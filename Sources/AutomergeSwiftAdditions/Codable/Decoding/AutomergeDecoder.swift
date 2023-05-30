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
//
//    // decode JSON from a JSONValue
//    @inlinable public func decode<T: Decodable>(_: T.Type, from json: JSONValue) throws -> T {
//        let decoder = JSONDecoderImpl(userInfo: userInfo, from: json, codingPath: [])
//        return try decoder.decode(T.self)
//    }
}

@usableFromInline struct AutomergeDecoderImpl {
    @usableFromInline let doc: Document
    @usableFromInline let codingPath: [CodingKey]
    @usableFromInline let userInfo: [CodingUserInfoKey: Any]

    @usableFromInline let automergeValue: AutomergeValue

    @inlinable init(
        doc: Document,
        userInfo: [CodingUserInfoKey: Any],
        from automergeValue: AutomergeValue,
        codingPath: [CodingKey]
    ) {
        self.doc = doc
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.automergeValue = automergeValue
    }

    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        try T(from: self)
    }
}

extension AutomergeDecoderImpl: Decoder {
    @usableFromInline func container<Key>(keyedBy _: Key.Type) throws ->
        KeyedDecodingContainer<Key> where Key: CodingKey
    {
        guard case let .object(dictionary) = self.automergeValue else {
            throw DecodingError.typeMismatch([String: AutomergeValue].self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected to decode \([String: AutomergeValue].self) but found \(self.automergeValue.debugDataTypeDescription) instead."
            ))
        }
        // dictionary: [String: AutomergeValue]
        let container = AutomergeKeyedDecodingContainer(
            impl: self,
            object: dictionary,
            codingPath: codingPath,
            doc: doc
        )
        return KeyedDecodingContainer(container)
    }

    @usableFromInline func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .array(array) = self.automergeValue else {
            throw DecodingError.typeMismatch([AutomergeValue].self, DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected to decode \([AutomergeValue].self) but found \(self.automergeValue.debugDataTypeDescription) instead."
            ))
        }

        return AutomergeUnkeyedDecodingContainer(
            impl: self,
            codingPath: self.codingPath,
            array: array
        )
    }

    @usableFromInline func singleValueContainer() throws -> SingleValueDecodingContainer {
        AutomergeSingleValueDecodingContainer(
            impl: self,
            codingPath: self.codingPath,
            automergeValue: self.automergeValue
        )
    }
}
