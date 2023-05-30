struct AutomergeKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K

    let impl: AutomergeDecoderImpl
    let codingPath: [CodingKey]
    let dictionary: [String: AutomergeValue]

    init(impl: AutomergeDecoderImpl, codingPath: [CodingKey], dictionary: [String: AutomergeValue]) {
        self.impl = impl
        self.codingPath = codingPath
        self.dictionary = dictionary
    }

    var allKeys: [K] {
        dictionary.keys.compactMap { K(stringValue: $0) }
    }

    func contains(_ key: K) -> Bool {
        if let _ = dictionary[key.stringValue] {
            return true
        }
        return false
    }

    func decodeNil(forKey key: K) throws -> Bool {
        let value = try getValue(forKey: key)
        return value == .null
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        let value = try getValue(forKey: key)

        guard case let .bool(bool) = value else {
            throw createTypeMismatchError(type: type, forKey: key, value: value)
        }

        return bool
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        let value = try getValue(forKey: key)

        guard case let .string(string) = value else {
            throw createTypeMismatchError(type: type, forKey: key, value: value)
        }

        return string
    }

    func decode(_: Double.Type, forKey key: K) throws -> Double {
        try decodeLosslessStringConvertible(key: key)
    }

    func decode(_: Float.Type, forKey key: K) throws -> Float {
        try decodeLosslessStringConvertible(key: key)
    }

    func decode(_: Int.Type, forKey key: K) throws -> Int {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int8.Type, forKey key: K) throws -> Int8 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int16.Type, forKey key: K) throws -> Int16 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int32.Type, forKey key: K) throws -> Int32 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int64.Type, forKey key: K) throws -> Int64 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt.Type, forKey key: K) throws -> UInt {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt8.Type, forKey key: K) throws -> UInt8 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt16.Type, forKey key: K) throws -> UInt16 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt32.Type, forKey key: K) throws -> UInt32 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt64.Type, forKey key: K) throws -> UInt64 {
        try decodeFixedWidthInteger(key: key)
    }

    func decode<T>(_: T.Type, forKey key: K) throws -> T where T: Decodable {
        let decoder = try decoderForKey(key)
        return try T(from: decoder)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws
        -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
    {
        try decoderForKey(key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        try decoderForKey(key).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        impl
    }

    func superDecoder(forKey _: K) throws -> Decoder {
        impl
    }
}

extension AutomergeKeyedDecodingContainer {
    private func decoderForKey(_ key: K) throws -> AutomergeDecoderImpl {
        let value = try getValue(forKey: key)
        var newPath = codingPath
        newPath.append(key)

        return AutomergeDecoderImpl(
            doc: impl.doc,
            userInfo: impl.userInfo,
            from: value,
            codingPath: newPath
        )
    }

    @inline(__always) private func getValue(forKey key: K) throws -> AutomergeValue {
        guard let value = dictionary[key.stringValue] else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."
            ))
        }

        return value
    }

    @inline(__always) private func createTypeMismatchError(type: Any.Type, forKey key: K, value: AutomergeValue) ->
        DecodingError
    {
        let codingPath = codingPath + [key]
        return DecodingError.typeMismatch(type, .init(
            codingPath: codingPath,
            debugDescription: "Expected to decode \(type) but found \(value.debugDataTypeDescription) instead."
        ))
    }

    @inline(__always) private func decodeFixedWidthInteger<T: FixedWidthInteger>(key: Self.Key) throws -> T {
        let value = try getValue(forKey: key)

        switch value {
        case let .int(intValue):
            return T(intValue)
        case let .uint(intValue):
            return T(intValue)
        default:
            throw createTypeMismatchError(type: T.self, forKey: key, value: value)
        }
    }

    @inline(__always) private func decodeLosslessStringConvertible<T: LosslessStringConvertible>(
        key: Self.Key
    ) throws -> T {
        let value = try getValue(forKey: key)

        guard case let .double(number) = value else {
            throw createTypeMismatchError(type: T.self, forKey: key, value: value)
        }

        guard let floatingPoint = T(number.description) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Parsed Automerge number <\(number)> does not fit in \(T.self)."
            )
        }

        return floatingPoint
    }
}
