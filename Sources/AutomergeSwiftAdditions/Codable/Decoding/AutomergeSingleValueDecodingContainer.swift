import struct Automerge.Counter
import class Automerge.Document
import struct Automerge.ObjId
import protocol Automerge.ScalarValueRepresentable
import Foundation

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
        // FIXME: search for and capture flows for Text

        switch T.self {
        case is Date.Type:
            if case let AutomergeValue.timestamp(intValue) = value {
                return Date(timeIntervalSince1970: Double(intValue)) as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.timestamp`."
                ))
            }
        case is Data.Type:
            if case let AutomergeValue.bytes(data) = value {
                return data as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.data`."
                ))
            }
        case is Counter.Type:
            if case let AutomergeValue.counter(counterValue) = value {
                return Counter(counterValue) as! T
            } else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode \(T.self) from \(value), but it wasn't a `.counter`."
                ))
            }
//        case is Text.Type:
//            // Capture and override the default encodable pathing for Counter since
//            // Automerge supports it as a primitive value type.
//            let downcastText = value as! Text
//            // FIXME: check to see if the object exists here before just splatting a new one into place
//            let textNode = try document.putObject(obj: objectId, key: key.stringValue, ty: .Text)
//
//            // Iterate through
//            let currentText = try! document.text(obj: textNode).utf8
//            let diff: CollectionDifference<String.UTF8View.Element> = downcastText.value.utf8
//                .difference(from: currentText)
//            for change in diff {
//                switch change {
//                case let .insert(offset, element, _):
//                    let char = String(bytes: [element], encoding: .utf8)
//                    try document.spliceText(obj: textNode, start: UInt64(offset), delete: 0, value: char)
//                case let .remove(offset, _, _):
//                    try document.spliceText(obj: textNode, start: UInt64(offset), delete: 1)
//                }

        default:
            return try T(from: impl)
        }
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
