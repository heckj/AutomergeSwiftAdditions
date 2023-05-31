import class Automerge.Document
import struct Automerge.ObjId
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

        // FIXME: Do lookup of ObjectId from Automerge doc based on codingPath
        // and stash it locally, then use to generate relevant containers - adding
        // it into their initializers to _require_ an ObjectId - that way we move
        // all the lookups into direct-to-Automerge doc code, and don't build a
        // paralell AutomergeType structure.
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
        let container = AutomergeKeyedDecodingContainer<Key>(
            impl: self,
            codingPath: codingPath,
            dictionary: dictionary
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
