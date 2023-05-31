import class Automerge.Document
import struct Automerge.ObjId
import Foundation

public struct AutomergeDecoder {
    public var codingPath: [CodingKey]
        
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public let doc: Document

    public init(doc: Document) {
        self.doc = doc
        self.codingPath = []
    }

    // decode type from an Automerge Value
    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        let decoder = AutomergeDecoderImpl(
            doc: doc,
            userInfo: userInfo,
            codingPath: []
        )
        return try decoder.decode(T.self)
    }
}
