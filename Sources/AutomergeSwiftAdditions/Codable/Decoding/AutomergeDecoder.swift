import Foundation

public struct AutomergeDecoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

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

// @usableFromInline struct JSONDecoderImpl {
//    @usableFromInline let codingPath: [CodingKey]
//    @usableFromInline let userInfo: [CodingUserInfoKey: Any]
//
//    @usableFromInline let json: AutomergeValue
//
//    @inlinable init(userInfo: [CodingUserInfoKey: Any], from json: AutomergeValue, codingPath: [CodingKey]) {
//        self.userInfo = userInfo
//        self.codingPath = codingPath
//        self.json = json
//    }
//
//    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
//        try T(from: self)
//    }
// }
//
// extension JSONDecoderImpl: Decoder {
//    @usableFromInline func container<Key>(keyedBy _: Key.Type) throws ->
//        KeyedDecodingContainer<Key> where Key: CodingKey
//    {
//        guard case .object(let dictionary) = self.json else {
//            throw DecodingError.typeMismatch([String: AutomergeValue].self, DecodingError.Context(
//                codingPath: self.codingPath,
//                debugDescription: "Expected to decode \([String: AutomergeValue].self) but found \(self.json.debugDataTypeDescription) instead."
//            ))
//        }
//
//        let container = JSONKeyedDecodingContainer<Key>(
//            impl: self,
//            codingPath: codingPath,
//            dictionary: dictionary
//        )
//        return KeyedDecodingContainer(container)
//    }
//
//    @usableFromInline func unkeyedContainer() throws -> UnkeyedDecodingContainer {
//        guard case .array(let array) = self.json else {
//            throw DecodingError.typeMismatch([AutomergeValue].self, DecodingError.Context(
//                codingPath: self.codingPath,
//                debugDescription: "Expected to decode \([AutomergeValue].self) but found \(self.json.debugDataTypeDescription) instead."
//            ))
//        }
//
//        return JSONUnkeyedDecodingContainer(
//            impl: self,
//            codingPath: self.codingPath,
//            array: array
//        )
//    }
//
//    @usableFromInline func singleValueContainer() throws -> SingleValueDecodingContainer {
//        JSONSingleValueDecodingContainter(
//            impl: self,
//            codingPath: self.codingPath,
//            json: self.json
//        )
//    }
// }
