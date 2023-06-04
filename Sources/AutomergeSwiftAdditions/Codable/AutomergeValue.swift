import struct Automerge.ObjId
import enum Automerge.ObjType
import enum Automerge.ScalarValue
import enum Automerge.Value
import Foundation

/// A type that represents all the potential options that the Automerge schema represents.
///
/// AutomergeType is a generalized representation of the same schema components that
/// Automerge supports, and allows us to represent the same structure as an Automerge schema
/// as nested enums for the purposes of temporarily storing, encoding, or decoding values.
public enum AutomergeValue: Equatable, Hashable {
    /// A list CRDT.
    case array([AutomergeValue])
    /// A map CRDT.
    case object([String: AutomergeValue])
    /// A specialized list CRDT for representing text.
    case text(String) // String
    /// A byte buffer.
    case bytes(Data)
    /// A string.
    case string(String)
    /// An unsigned integer.
    case uint(UInt64)
    /// A signed integer.
    case int(Int64)
    /// A floating point number.
    case double(Double)
    /// An integer counter.
    case counter(Int64)
    /// A timestamp represented by the milliseconds since UNIX epoch.
    case timestamp(Int64)
    /// A Boolean value.
    case bool(Bool)
    /// An unknown, raw scalar type.
    ///
    /// This type is reserved for forward compatibility, and is not expected to be created directly.
    case unknown(typeCode: UInt8, data: Data)
    case null

    /// Returns an Automerge ScalarValue from the Codable AutomergeValue when available.
    /// - Returns: returns nil if the value doesn't map into Automerge's ScalarValue enum.
    public func scalarValue() -> ScalarValue? {
        switch self {
        case let .bytes(data):
            return .Bytes(data)
        case let .string(string):
            return .String(string)
        case let .uint(uInt64):
            return .Uint(uInt64)
        case let .int(int64):
            return .Int(int64)
        case let .double(double):
            return .F64(double)
        case let .counter(int64):
            return .Counter(int64)
        case let .timestamp(int64):
            return .Timestamp(int64)
        case let .bool(bool):
            return .Boolean(bool)
        default:
            return nil
        }
    }

    public static func fromValue(_ value: Value) -> Self {
        switch value {
        case let .Object(_, typeOfObject):
            switch typeOfObject {
            case .Text:
                return .text("")
            case .Map:
                return .object([:])
            case .List:
                return .array([])
            }
        case let .Scalar(scalarValue):
            switch scalarValue {
            case let .Bytes(data):
                return .bytes(data)
            case let .String(str):
                return .string(str)
            case let .Uint(intValue):
                return .uint(intValue)
            case let .Int(intValue):
                return .int(intValue)
            case let .F64(doubleValue):
                return .double(doubleValue)
            case let .Counter(counterValue):
                return .counter(counterValue)
            case let .Timestamp(intValue):
                return .timestamp(intValue)
            case let .Boolean(boolValue):
                return .bool(boolValue)
            case let .Unknown(typeCode: typeCode, data: data):
                return .unknown(typeCode: typeCode, data: data)
            case .Null:
                return .null
            }
        }
    }
}

extension AutomergeValue {
    // used for creating type mismatch errors possible when decoding

    var debugDataTypeDescription: String {
        switch self {
        case .array:
            return "an array"
        case .bool:
            return "bool"
        case .string:
            return "a string"
        case .object:
            return "a dictionary"
        case .null:
            return "null"
        case .text:
            return "a scalar text value"
        case .bytes:
            return "bytes"
        case .uint:
            return "an unsigned integer"
        case .int:
            return "a signed integer"
        case .double:
            return "a floating point value"
        case .counter:
            return "a counter"
        case .timestamp:
            return "a timestamp"
        case let .unknown(typeCode: typeCode, data: data):
            return "an unknown value with typeCode \(typeCode) and data \(data)"
        }
    }
}

public func == (lhs: AutomergeValue, rhs: AutomergeValue) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
        return true
    case let (.bool(lhs), .bool(rhs)):
        return lhs == rhs
    case let (.int(lhs), .int(rhs)):
        return lhs == rhs
    case let (.uint(lhs), .uint(rhs)):
        return lhs == rhs
    case let (.double(lhs), .double(rhs)):
        return lhs == rhs
    case let (.bytes(lhs), .bytes(rhs)):
        return lhs == rhs
    case let (.counter(lhs), .counter(rhs)):
        return lhs == rhs
    case let (.timestamp(lhs), .timestamp(rhs)):
        return lhs == rhs
    case let (.string(lhs), .string(rhs)):
        return lhs == rhs
    case let (.array(lhs), .array(rhs)):
        guard lhs.count == rhs.count else {
            return false
        }

        var lhsiterator = lhs.makeIterator()
        var rhsiterator = rhs.makeIterator()

        while let lhs = lhsiterator.next(), let rhs = rhsiterator.next() {
            if lhs == rhs {
                continue
            }
            return false
        }

        return true
    case let (.object(lhs), .object(rhs)):
        guard lhs.count == rhs.count else {
            return false
        }

        var lhsiterator = lhs.makeIterator()

        while let (lhskey, lhsvalue) = lhsiterator.next() {
            guard let rhsvalue = rhs[lhskey] else {
                return false
            }

            if lhsvalue == rhsvalue {
                continue
            }
            return false
        }

        return true
    default:
        return false
    }
}
