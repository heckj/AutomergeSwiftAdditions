import class Automerge.Document
import struct Automerge.ObjId
import protocol Automerge.ScalarValueRepresentable

struct AutomergeSingleValueDecodingContainer: SingleValueDecodingContainer {
    let impl: AutomergeDecoderImpl
    let value: AutomergeValue
    let codingPath: [CodingKey]

    let objectId: ObjId

    init(impl: AutomergeDecoderImpl, codingPath: [CodingKey], automergeValue: AutomergeValue, objectId: ObjId) {
        self.impl = impl
        self.codingPath = codingPath
        value = automergeValue
        self.objectId = objectId
    }

    func decodeNil() -> Bool {
        value == .null
    }

    func decode(_: Bool.Type) throws -> Bool {
        guard case let .bool(bool) = value else {
            throw createTypeMismatchError(type: Bool.self, value: value)
        }

        return bool
    }

    func decode(_: String.Type) throws -> String {
        guard case let .string(string) = value else {
            throw createTypeMismatchError(type: String.self, value: value)
        }

        return string
    }

    func decode(_: Double.Type) throws -> Double {
        guard case let .double(double) = value else {
            throw createTypeMismatchError(type: Double.self, value: value)
        }
        return double
    }

    func decode(_: Float.Type) throws -> Float {
        guard case let .double(double) = value else {
            throw createTypeMismatchError(type: Double.self, value: value)
        }
        return Float(double)
    }

    func decode(_: Int.Type) throws -> Int {
        guard case let .int(intValue) = value else {
            throw createTypeMismatchError(type: Int.self, value: value)
        }
        return Int(intValue)
    }

    func decode(_: Int8.Type) throws -> Int8 {
        guard case let .int(intValue) = value else {
            throw createTypeMismatchError(type: Int8.self, value: value)
        }
        return Int8(intValue)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        guard case let .int(intValue) = value else {
            throw createTypeMismatchError(type: Int16.self, value: value)
        }
        return Int16(intValue)
    }

    func decode(_: Int32.Type) throws -> Int32 {
        guard case let .int(intValue) = value else {
            throw createTypeMismatchError(type: Int32.self, value: value)
        }
        return Int32(intValue)
    }

    func decode(_: Int64.Type) throws -> Int64 {
        guard case let .int(intValue) = value else {
            throw createTypeMismatchError(type: Int64.self, value: value)
        }
        return intValue
    }

    func decode(_: UInt.Type) throws -> UInt {
        guard case let .uint(uintValue) = value else {
            throw createTypeMismatchError(type: UInt.self, value: value)
        }
        return UInt(uintValue)
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        guard case let .uint(uintValue) = value else {
            throw createTypeMismatchError(type: UInt8.self, value: value)
        }
        return UInt8(uintValue)
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        guard case let .uint(uintValue) = value else {
            throw createTypeMismatchError(type: UInt16.self, value: value)
        }
        return UInt16(uintValue)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        guard case let .uint(uintValue) = value else {
            throw createTypeMismatchError(type: UInt32.self, value: value)
        }
        return UInt32(uintValue)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        guard case let .uint(uintValue) = value else {
            throw createTypeMismatchError(type: UInt64.self, value: value)
        }
        return uintValue
    }

    mutating func decode<S>(_: S.Type) throws -> S where S: ScalarValueRepresentable {
        if let scalarValue = value.scalarValue() {
            let conversionResult = S.fromScalarValue(scalarValue)
            switch conversionResult {
            case let .success(success):
                return success
            case let .failure(failure):
                throw DecodingError.typeMismatch(S.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(S.self) but found \(value) instead.",
                    underlyingError: failure
                ))
            }
        } else {
            throw createTypeMismatchError(type: S.self, value: value)
        }
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        // FIXME: search for and capture flows for Date, Counter, Data, and Text
        try T(from: impl)
    }
}

extension AutomergeSingleValueDecodingContainer {
    @inline(__always) private func createTypeMismatchError(type: Any.Type, value: AutomergeValue) -> DecodingError {
        DecodingError.typeMismatch(type, .init(
            codingPath: codingPath,
            debugDescription: "Expected to decode \(type) but found \(value.debugDataTypeDescription) instead."
        ))
    }
}
