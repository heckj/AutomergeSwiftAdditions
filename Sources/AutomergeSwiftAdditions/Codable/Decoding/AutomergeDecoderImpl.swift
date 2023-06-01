import class Automerge.Document
import struct Automerge.ObjId
import enum Automerge.Value
import Foundation

/* Code flow example from a user-defined Decoder implementation

    let values = try decoder.container(keyedBy: CodingKeys.self)
    latitude = try values.decode(Double.self, forKey: .latitude)
    longitude = try values.decode(Double.self, forKey: .longitude)

    let additionalInfo = try values.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
    elevation = try additionalInfo.decode(Double.self, forKey: .elevation)

 */

@usableFromInline struct AutomergeDecoderImpl {
    @usableFromInline let doc: Document
    @usableFromInline let codingPath: [CodingKey]
    @usableFromInline let userInfo: [CodingUserInfoKey: Any]

    @inlinable init(
        doc: Document,
        userInfo: [CodingUserInfoKey: Any],
        codingPath: [CodingKey]
    ) {
        self.doc = doc
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        try T(from: self)
    }
}

extension AutomergeDecoderImpl: Decoder {
    @usableFromInline func container<Key>(keyedBy _: Key.Type) throws ->
        KeyedDecodingContainer<Key> where Key: CodingKey
    {
        let result = AnyCodingKey.retrieveObjectId(
            document: self.doc,
            path: codingPath,
            containerType: .Key,
            strategy: .readonly
        )
        switch result {
        case let .success((objectId, _)):
            let objectType = doc.objectType(obj: objectId)
            guard case .Map = objectType else {
                throw DecodingError.typeMismatch([String: AutomergeValue].self, DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "ObjectId \(objectId) returned an type of \(objectType)."
                ))
            }

            let container = AutomergeKeyedDecodingContainer<Key>(
                impl: self,
                codingPath: codingPath,
                objectId: objectId
            )
            return KeyedDecodingContainer(container)
        case let .failure(err):
            throw err
        }
    }

    @usableFromInline func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let result = AnyCodingKey.retrieveObjectId(
            document: self.doc,
            path: codingPath,
            containerType: .Index,
            strategy: .readonly
        )
        switch result {
        case let .success((objectId, _)):
            let objectType = doc.objectType(obj: objectId)
            guard case .List = objectType else {
                throw DecodingError.typeMismatch([String: AutomergeValue].self, DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "ObjectId \(objectId) returned an type of \(objectType)."
                ))
            }

            return AutomergeUnkeyedDecodingContainer(
                impl: self,
                codingPath: self.codingPath,
                array: [],
                objectId: objectId
            )
        case let .failure(err):
            throw err
        }
    }

    @usableFromInline func singleValueContainer() throws -> SingleValueDecodingContainer {
        let result = AnyCodingKey.retrieveObjectId(
            document: self.doc,
            path: codingPath,
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success((objectId, finalKey)):

            let foo: Value?
            if let indexValue = finalKey.intValue {
                foo = try doc.get(obj: objectId, index: UInt64(indexValue))
            } else {
                foo = try doc.get(obj: objectId, key: finalKey.stringValue)
            }
            guard let value = foo else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Attempted to read value at \(objectId) with coding key: \(finalKey), and no value was returned."
                    )
                )
            }

            return AutomergeSingleValueDecodingContainer(
                impl: self,
                codingPath: self.codingPath,
                automergeValue: AutomergeValue.fromValue(value),
                objectId: objectId
            )
        case let .failure(err):
            throw err
        }
    }
}
