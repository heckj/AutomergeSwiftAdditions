import class Automerge.Document
import struct Automerge.ObjId

private func tracePrint(_ stringval: String) {
    #if DEBUG
    print(stringval)
    #endif
}

extension AutomergeEncoderImpl {
    /// Returns an Automerge objectId for the location within the document.
    ///
    /// The function looks up Automerge schema while optionally creating schema if needed, and reporting on errors with
    /// conflicting schema.
    /// Control the pattern of when to create schema and what errors to throw by setting the `strategy` property.
    ///
    /// - Parameters:
    ///   - path: An array of instances conforming to CodingKey that make up the schema path.
    ///   - type: The container type for the lookup, which effects what is returned and at what level of the path.
    ///   - strategy: The strategy for creating schema during encoding if it doesn't exist or conflicts with existing
    /// schema. The strategy defaults to ``AutomergeEncoder/SchemaStrategy/default``.
    /// - Returns: A result type that contains a tuple of an Automerge object Id of the relevant container and the final
    /// CodingKey value, or an error if the retrieval failed or there was conflicting schema within in the document.
    func retrieveObjectId(
        path: [CodingKey],
        containerType: EncodingContainerType,
        strategy: AutomergeEncoder.SchemaStrategy = .default
    ) -> Result<(ObjId, AnyCodingKey), Error> {
        // This method returns a Result type because the Codable protocol constrains the
        // container initializers to not throw on initialization.
        // Instead we stash the lookup failure into the container, and throw the relevant
        // error on any call to one of the `.encode()` methods, which do throw.
        // This defers the error condition, and the container is essentially invalid in this
        // state, but it provides a smoother integration with Codable.

        // Path scenarios by the type of Codable container that invokes the lookup.
        //
        // [] + Key -> ObjId.ROOT
        // [] + Index = error
        // [] + Value = error
        // [foo] + Value = ObjId.Root
        // [foo] + Index = error
        // [foo] + Key = ObjId.lookup(/Root/foo)   (container)
        // [1] + (Value|Index|Key) = error (root is always a map)
        // [foo, 1] + Value = /Root/foo, index 1
        // [foo, 1] + Index = /Root/foo, index 1   (container)
        // [foo, 1] + Key = /Root/foo, index 1     (container)
        // [foo, bar] + Value = /Root/foo, key bar
        // [foo, bar] + Index = /Root/foo, key bar (container)
        // [foo, bar] + Key = /Root/foo, key bar   (container)

        // Pre-allocate an array the same length as `path` for ObjectId lookups
        var matchingObjectIds: [Int: ObjId] = [:]
        matchingObjectIds.reserveCapacity(path.count)

        // - Efficiency boost using a cache
        // Iterate from the N-1 end of path, backwards - checking [] -> (ObjectId, ObjType) cache,
        // checking until we get a positive hit from the cache. Worst case there'll be nothing in
        // the cache and we iterate to the bottom. Save that as the starting cursor position.
        let startingPosition = 0
        var previousObjectId = ObjId.ROOT

        if strategy == .override {
            return .failure(CodingKeyLookupError.unexpectedLookupFailure("Override strategy not yet implemented"))
        }

        // initial conditions if we're handed an empty path
        if path.isEmpty {
            switch containerType {
            case .Key:
                return .success((ObjId.ROOT, AnyCodingKey.ROOT))
            case .Index:
                return .failure(
                    CodingKeyLookupError
                        .invalidIndexLookup("An empty path refers to ROOT and is always a map.")
                )
            case .Value:
                return .failure(
                    CodingKeyLookupError
                        .invalidValueLookup("An empty path refers to ROOT and is always a map.")
                )
            }
        }

//        let anypath = path.map { AnyCodingKey($0) }
        tracePrint(
            "`retrieveObjectId` with path [\(path.map { AnyCodingKey($0) })] for container type \(containerType), with stragegy: \(strategy)"
        )
        // Iterate the cursor position forward doing lookups against the Automerge document
        // until we get to the second-to-last element. This range ensures that we're iterating
        // over "expected containers"
        for position in startingPosition ..< (path.count - 1) {
            tracePrint("Checking position \(position): '\(path[position])'")
            // Strategy to use while creating schema:
            // defined in AutomergeEncoder.SchemaStrategy

            // (default)
            // schema-create-on-nil: If the schema *doesn't* exist - nil lookups when searched - create
            // the relevant schema as it goes. This doesn't account for any specific value types or type checking.
            //
            // schema-error-on-type-mismatch: If schema in Automerge is a scalar value, Text, or mis-matched
            // list/object types, throw an error instead of overwriting the schema.

            // (!override!)
            // schema-overwrite: Disregard any schema that currently exists and overwrite values as needed to
            // establish the schema that is being encoded.

            // (?readonly?)
            // read-only/super-double-strict: Only allow encoding into schema that is ALREADY present within
            // Automerge. Adding additional values (to a map, or to a list) would be invalid in these cases.
            // In a large sense, it's an "update values only" kind of scenario.

            // Determine the type of the previous element by inspecting the current path.
            // If it's got an index value, then it's a reference in a list.
            // Otherwise it's a key on an object.
            if let indexValue = path[position].intValue {
                tracePrint("Checking against index position \(indexValue).")
                // If it's an index, verify that it doesn't represent an element beyond the end of an existing list.
                if indexValue > self.document.length(obj: previousObjectId) {
                    if strategy == .readonly {
                        return .failure(
                            CodingKeyLookupError
                                .indexOutOfBounds(
                                    "Index value \(indexValue) is beyond the length: \(self.document.length(obj: previousObjectId)) and schema is read-only"
                                )
                        )
                    } else if indexValue > (self.document.length(obj: previousObjectId) + 1) {
                        return .failure(
                            CodingKeyLookupError
                                .indexOutOfBounds(
                                    "Index value \(indexValue) is too far beyond the length: \(self.document.length(obj: previousObjectId)) to append a new item."
                                )
                        )
                    }
                }

                // Look up Automerge `Value` matching this index within the list
                do {
                    if let value = try self.document.get(obj: previousObjectId, index: UInt64(indexValue)) {
                        switch value {
                        case let .Object(objId, objType):
                            //                EncoderPathCache.upsert(extendedPath, value: (objId, objType))
                            // if the type of Object is Text, we should error here because the schema can't extend
                            // through a
                            // leaf node
                            if objType == .Text {
                                // If the looked up Value is a Text node, then it's a leaf on the schema structure.
                                // If there's remaining values to be looked up, the overall path is invalid.
                                return .failure(
                                    CodingKeyLookupError
                                        .pathExtendsThroughText(
                                            "Path at \(path[0 ... position]) is a Text object, which is not a container - and the path has additional elements: \(path[(position + 1)...])."
                                        )
                                )
                            }
                            matchingObjectIds[position] = objId
                            previousObjectId = objId
                            tracePrint("Found \(path[0 ... position]) as objectId \(objId) of type \(objType)")
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .pathExtendsThroughScalar(
                                        "Path at \(path[0 ... position]) is a single value, not a container - and the path has additional elements: \(path[(position + 1)...])."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        tracePrint(
                            "Nothing pre-existing in schema at \(path[0 ... position]), will need to create a container."
                        )
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .schemaMissing(
                                        "Nothing in schema exists at \(path[0 ... position]) - look u returns nil"
                                    )
                            )
                        } else { // couldn't find the object via lookup, so we need to create it
                            // Look up the kind of object to create by inspecting the "next path" element
                            tracePrint("Need to create a container at \(path[0 ... position]).")
                            tracePrint("Next path element is '\(path[position + 1])'.")
                            if let _ = path[position + 1].intValue {
                                // the next item is a list, so create a new list within this list at the index value the
                                // current position indicates.
                                let newObjectId = try self.document.insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .List
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint("created \(path[0 ... position]) as objectId \(newObjectId) of type List")
                                // add to cache
                                //                        EncoderPathCache.upsert(extendedPath,value: (newObjectId,
                                //                        .List))
                            } else {
                                // need to create an object
                                let newObjectId = try self.document.insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .Map
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint("created \(path[0 ... position]) as objectId \(newObjectId) of type Map")
                                // add to cache
                                //                        EncoderPathCache.upsert(extendedPath,value: (newObjectId,
                                //                        .Map))
                                // carry on with remaining path elements
                            }
                        }
                    }
                } catch {
                    return .failure(error)
                }
            } else { // path[position] is a string-based key, so we need to get - or insert - an Object
                let keyValue = path[position].stringValue
                tracePrint("Checking against key \(keyValue).")
                do {
                    if let value = try self.document.get(obj: previousObjectId, key: keyValue) {
                        switch value {
                        case let .Object(objId, objType):
                            //                EncoderPathCache.upsert(extendedPath, value: (objId, objType))

                            // If the looked up Value is a Text node, then it's a leaf on the schema structure.
                            // If there's remaining values to be looked up, the overall path is invalid.
                            if objType == .Text {
                                return .failure(
                                    CodingKeyLookupError
                                        .pathExtendsThroughText(
                                            "Path at \(path[0 ... position]) is a Text object, which is not a container - and the path has additional elements: \(path[(position + 1)...])."
                                        )
                                )
                            }
                            matchingObjectIds[position] = objId
                            previousObjectId = objId
                            tracePrint("Found \(path[0 ... position]) as objectId \(objId) of type \(objType)")
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            // If there's remaining values to be looked up, the overall path is invalid.
                            return .failure(
                                CodingKeyLookupError
                                    .pathExtendsThroughScalar(
                                        "Path at \(path[0 ... position]) is a single value, not a container - and the path has additional elements: \(path[(position + 1)...])."
                                    )
                            )
                        }
                    } else { // value returned from doc.get() is nil, we'll need to create it
                        tracePrint(
                            "Nothing pre-existing in schema at \(path[0 ... position]), will need to create a container."
                        )
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .schemaMissing(
                                        "Nothing in schema exists at \(path[0 ... position]) - look u returns nil"
                                    )
                            )
                        } else { // looked-up value was nil AND we're not read-only, create the object
                            tracePrint("Need to create a container at \(path[0 ... position]).")
                            tracePrint("Next path element is \(path[position + 1]).")
                            // Look up the kind of object to create by inspecting the "next path" element
                            if let _ = path[position + 1].intValue {
                                // the next item is a list, so create a new list within this object using the key value
                                // the current position indicates.
                                let newObjectId = try self.document.putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .List
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint("created \(path[0 ... position]) as objectId \(newObjectId) of type List")
                                // add to cache
                                //                       EncoderPathCache.upsert(extendedPath, value: (newObjectId,
                                //                        .List))
                            } else {
                                // the next item is an object, so create a new object within this object using the key
                                // value the current position indicates.
                                let newObjectId = try self.document.putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .Map
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint("created \(path[0 ... position]) as objectId \(newObjectId) of type Map")
                                // add to cache
                                //                       EncoderPathCache.upsert(extendedPath, value: (newObjectId,
                                //                        .Map))
                                // carry on with remaining pathelements
                            }
                        }
                    }
                } catch {
                    return .failure(error)
                }
            }
        }

        #if DEBUG
        tracePrint("All prior containers created or found:")
        for position in startingPosition ..< (path.count - 1) {
            tracePrint("   \(position) -> \(String(describing: matchingObjectIds[position]))")
        }
        #endif

        // Then what we do depends on the type of lookup.
        // - on SingleValueContainer, we return the second-to-last objectId and the key and/or Index
        // - on KeyedContainer or UnkeyedContainer, we look up and return the final objectId
        let finalpiece = path[path.count - 1]
        switch containerType {
        case .Index, .Key: // the element that we're looking up (or creating) is for a key or index container
            if let indexValue = finalpiece.intValue { // The value within the CodingKey indicates it's a List
                tracePrint("Final piece of the path is '\(finalpiece)', index \(indexValue) of a List.")
                // short circuit beyond-length of array
                if indexValue > self.document.length(obj: previousObjectId) {
                    if strategy == .readonly {
                        return .failure(
                            CodingKeyLookupError
                                .indexOutOfBounds(
                                    "Index value \(indexValue) is beyond the length: \(self.document.length(obj: previousObjectId)) and schema is read-only"
                                )
                        )
                    } else if indexValue > (self.document.length(obj: previousObjectId) + 1) {
                        return .failure(
                            CodingKeyLookupError
                                .indexOutOfBounds(
                                    "Index value \(indexValue) is too far beyond the length: \(self.document.length(obj: previousObjectId)) to append a new item."
                                )
                        )
                    }
                }

                // Look up Automerge `Value` matching this index within the list
                do {
                    tracePrint("Look up what's at index \(indexValue) of objectId: \(previousObjectId):")
                    if let value = try self.document.get(obj: previousObjectId, index: UInt64(indexValue)) {
                        switch value {
                        case let .Object(objId, objType):
                            switch objType {
                            case .Text:
                                return .failure(
                                    CodingKeyLookupError
                                        .mismatchedSchema(
                                            "Path at \(path) is a Text object, which is not the List container that we expected."
                                        )
                                )
                            case .Map:
                                return .failure(
                                    CodingKeyLookupError
                                        .mismatchedSchema(
                                            "Path at \(path) is an object container, which is not the List container that we expected."
                                        )
                                )
                            case .List:
                                //                            EncoderPathCache.upsert(extendedPath, value: (objId,
                                //                            objType))
                                tracePrint("Found List container with ObjectId \(objId).")
                                return .success((objId, AnyCodingKey("")))
                            }
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .mismatchedSchema(
                                        "Path at \(path) is an scalar value, which is not the List container that we expected."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .schemaMissing(
                                        "Nothing in schema exists at \(path) - look u returns nil"
                                    )
                            )
                        } else {
                            // need to create a list within the list
                            let newObjectId = try self.document.insertObject(
                                obj: previousObjectId,
                                index: UInt64(indexValue),
                                ty: .List
                            )
                            //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                            tracePrint("Created new List container with ObjectId \(newObjectId).")
                            return .success((newObjectId, AnyCodingKey("")))
                        }
                    }
                } catch {
                    return .failure(error)
                }
            } else { // final path element is a key
                let keyValue = finalpiece.stringValue

                // Look up Automerge `Value` matching this key on an object
                do {
                    tracePrint("Look up what's at key '\(keyValue)' of objectId: \(previousObjectId).")
                    if let value = try self.document.get(obj: previousObjectId, key: keyValue) {
                        switch value {
                        case let .Object(objId, objType):
                            switch objType {
                            case .Text:
                                return .failure(
                                    CodingKeyLookupError
                                        .mismatchedSchema(
                                            "Path at \(path) is a Text object, which is not the List container that we expected."
                                        )
                                )
                            case .Map:
                                //                            EncoderPathCache.upsert(extendedPath, value: (objId,
                                //                            objType))
                                tracePrint("Found Map container with ObjectId \(objId).")
                                return .success((objId, AnyCodingKey("")))
                            case .List:
                                return .failure(
                                    CodingKeyLookupError
                                        .mismatchedSchema(
                                            "Path at \(path) is a List container, which is not the object container that we expected."
                                        )
                                )
                            }
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .mismatchedSchema(
                                        "Path at \(path) is an scalar value, which is not the List container that we expected."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .schemaMissing(
                                        "Nothing in schema exists at \(path) - look u returns nil"
                                    )
                            )
                        } else {
                            // need to create a list within the map
                            let newObjectId = try self.document.putObject(
                                obj: previousObjectId,
                                key: keyValue,
                                ty: .Map
                            )
                            //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                            tracePrint("Created new Map container with ObjectId \(newObjectId).")
                            return .success((newObjectId, AnyCodingKey("")))
                        }
                    }
                } catch {
                    return .failure(error)
                }
            }
        case .Value:
            guard let containerObjectId = matchingObjectIds[path.count - 2] else {
                fatalError(
                    "objectId lookups failed to identify object Id for the second to last element in path: \(path)"
                )
            }
            return .success((containerObjectId, AnyCodingKey(finalpiece)))
        }
    }
}
