import Automerge
import Foundation

class PathCache {
    static var objId: [String: (ObjId, ObjType)] = [:]
}

/// Path Errors
public enum PathParseError: Error {
    /// The path element is not valid.
    case invalidPathElement(String)
    /// The path element, structured as a Index location, doesn't include an index value.
    case emptyListIndex(String)
    /// The list index requested was longer than the list in the Document.
    case indexOutOfBounds(String)
}

extension Document {
    /// Looks up the objectId represented by the path string you provide.
    /// - Parameter path: A string representation of the location within an Automerge document.
    /// - Returns: The objectId at the schema location you provide, or nil if the path is valid and no object exists in
    /// the document.
    ///
    /// The method throws errors on invalid paths
    public func lookupPath(path: String) throws -> ObjId? {
        if path.first == "." {
            if let cacheResult = PathCache.objId[path] {
                return cacheResult.0
            }
        } else {
            if let cacheResult = PathCache.objId["." + path] {
                return cacheResult.0
            }
        }
        // breaks up the provided path, breaking on '.' and copying the results into their own Strings
        let bits = path.split(separator: ".").map { String($0) }
        if bits.isEmpty {
            return ObjId.ROOT
        }
        return try lookupSubPath(bits, basePath: "", from: ObjId.ROOT)
    }

    private func extractIndexString(pathElement: String) throws -> UInt64 {
        if pathElement.first == "[", pathElement.last == "]" {
            let start = pathElement.index(after: pathElement.startIndex)
            let end = pathElement.index(before: pathElement.endIndex)
            let substring = String(pathElement[start ..< end])
            if !substring.isEmpty, let parsedIndexValue = UInt64(substring) {
                return parsedIndexValue
            } else {
                throw PathParseError.emptyListIndex(String(pathElement))
            }
        } else {
            throw PathParseError.invalidPathElement(String(pathElement))
        }
    }

    private func lookupSubPath(_ pathList: [String], basePath: String, from obj: ObjId) throws -> ObjId? {
        guard let pathPiece = pathList.first,
              let firstChar: Character = pathPiece.first
        else {
            return obj
        }
        let remainingPathPieces = Array(pathList[1...])

        if firstChar == "[" {
            let indexValue = try extractIndexString(pathElement: pathPiece)
            if indexValue > length(obj: obj) {
                throw PathParseError
                    .indexOutOfBounds("Index value \(indexValue) is beyond the length: \(length(obj: obj))")
            }
            if let value = try get(obj: obj, index: indexValue) {
                switch value {
                case let .Object(objId, objType):
                    let extendedPath: String = [basePath, pathPiece].joined(separator: ".")
                    PathCache.objId[extendedPath] = (objId, objType)
                    return try lookupSubPath(remainingPathPieces, basePath: extendedPath, from: objId)
                case .Scalar:
                    return nil
                }
            } else {
                // path is a valid request, there's just nothing there
                return nil
            }
        } else if firstChar.isASCII,
                  firstChar.isLetter
        {
            if let value = try get(obj: obj, key: String(pathPiece)) {
                switch value {
                case let .Object(objId, objType):
                    let extendedPath: String = [basePath, pathPiece].joined(separator: ".")
                    PathCache.objId[extendedPath] = (objId, objType)
                    return try lookupSubPath(remainingPathPieces, basePath: extendedPath, from: objId)
                case .Scalar:
                    return nil
                }
            } else {
                // path is a valid request, there's just nothing there
                return nil
            }
        } else {
            throw PathParseError.invalidPathElement(String(pathPiece))
        }
    }
}

extension Sequence where Element == Automerge.PathElement {
    /// Returns a string that represents the schema path.
    func stringPath() -> String {
        let path = map { pathElement in
            switch pathElement.prop {
            case let .Index(idx):
                return String("[\(idx)]")
            case let .Key(key):
                return key
            }
        }.joined(separator: ".")
        return ".\(path)"
    }
}

extension Sequence where Element: CodingKey {
    /// Returns a string that represents the schema path.
    func stringPath() -> String {
        let path = map { pathElement in
            if let idx = pathElement.intValue {
                return String("[\(idx)]")
            } else {
                return pathElement.stringValue
            }
        }.joined(separator: ".")
        return ".\(path)"
    }
}