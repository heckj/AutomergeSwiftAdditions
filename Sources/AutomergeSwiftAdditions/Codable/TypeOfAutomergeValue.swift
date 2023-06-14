import enum Automerge.ScalarValue
import enum Automerge.Value

public enum TypeOfAutomergeValue: Equatable, Hashable {
    /// A list CRDT.
    case array
    /// A map CRDT.
    case object
    /// A specialized list CRDT for representing text.
    case text
    /// A byte buffer.
    case bytes
    /// A string.
    case string
    /// An unsigned integer.
    case uint
    /// A signed integer.
    case int
    /// A floating point number.
    case double
    /// An integer counter.
    case counter
    /// A timestamp represented by the milliseconds since UNIX epoch.
    case timestamp
    /// A Boolean value.
    case bool
    /// Nil.
    case unknown(UInt8)
    /// Nil.
    case null

    public static func from(_ val: Value) -> Self {
        switch val {
        case let .Object(_, objType):
            switch objType {
            case .List:
                return .array
            case .Map:
                return .object
            case .Text:
                return .text
            }
        case let .Scalar(scalarValue):
            switch scalarValue {
            case .Boolean:
                return .bool
            case .Bytes:
                return .bytes
            case .String:
                return .string
            case .Uint:
                return .uint
            case .Int:
                return .int
            case .F64:
                return .double
            case .Counter:
                return .counter
            case .Timestamp:
                return .timestamp
            case let .Unknown(type, _):
                return .unknown(type)
            case .Null:
                return .null
            }
        }
    }

    public static func from(_ val: ScalarValue) -> Self {
        switch val {
        case .Boolean:
            return .bool
        case .Bytes:
            return .bytes
        case .String:
            return .string
        case .Uint:
            return .uint
        case .Int:
            return .int
        case .F64:
            return .double
        case .Counter:
            return .counter
        case .Timestamp:
            return .timestamp
        case let .Unknown(type, _):
            return .unknown(type)
        case .Null:
            return .null
        }
    }
}
