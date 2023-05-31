import class Automerge.Document
import struct Automerge.ObjId
import Foundation

public struct AutomergeDecoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public let doc: Document

    public init(doc: Document) {
        self.doc = doc
    }

//    // decode JSON from a stream of bytes (array of bytes)
//    @inlinable public func decode<T: Decodable, Bytes: Collection>(_: T.Type, from bytes: Bytes)
//        throws -> T where Bytes.Element == UInt8
//    {
//        do {
//            let json = try JSONParser().parse(bytes: bytes)
//            return try self.decode(T.self, from: json)
//        } catch let error as JSONError {
//            throw error.decodingError
//        }
//    }

    // decode type from an Automerge Value
    @inlinable public func decode<T: Decodable>(_: T.Type, from automergeValue: AutomergeValue) throws -> T {
        let decoder = AutomergeDecoderImpl(
            doc: doc,
            userInfo: userInfo,
            from: automergeValue,
            codingPath: []
        )
        return try decoder.decode(T.self)
    }
}
