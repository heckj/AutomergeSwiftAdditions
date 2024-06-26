import Automerge
import Foundation

/// A type that can be represented within an Automerge document.
///
/// You can encode your own types to be used as scalar values in Automerge, or within ``ObjType/List`` or
/// ``ObjType/Map``
/// by conforming your type to `AutomergeRepresentable`.
/// Implement ``AutomergeRepresentable/toValue(doc:objId:)`` and ``AutomergeRepresentable/fromValue(_:)``with your
/// preferred encoding.
///
/// To treat your type as a scalar value with atomic updates, return a value of``ScalarValue/Bytes(_:)`` with the data
/// encoded
/// into the associated type, and read the bytes through ``AutomergeRepresentable/fromValue(_:)`` to decode into your
/// type.
public protocol AutomergeRepresentable {
    // NOTE(heckj): ScalarValueRepresentable has the pieces to convert into and out of types to Scalar values
    // within Automerge, but I don't (yet) have the same thing for Lists or Object/Map representations.
    // I want to try and accomplish that with a broader AutomergeRepresentable protocol. The initial version
    // of which is relevant to READ-ONLY determine a type within Automerge, but doesn't have the bits in place
    // to support conversions. When done, all AutomergeRepresentables should *also* be ScalarValueRepresentable.

    /// Converts the Automerge representation to a local type, or returns a failure
    /// - Parameter val: The Automerge ``Value`` to be converted as a scalar value into a local type.
    /// - Returns: The type, converted to a local type, or an error indicating the reason for the conversion failure.
    ///
    /// The protocol accepts defines a function to accept a ``Value`` primarily for convenience.
    /// ``Value`` is a higher level enumeration that can include object types such as ``ObjType/List``, ``ObjType/Map``,
    /// and ``ObjType/Text``.
    static func fromValue(_ val: Value) throws -> Self

    /// Converts a local type into an Automerge Value type.
    /// - Parameters:
    ///   - doc: The document your type is mapping into.
    ///   - objId: The object id.
    /// - Returns: The ``ScalarValue`` that aligns with the provided type or an error indicating the reason for the
    /// conversion failure.
    func toValue(doc: Document, objId: ObjId) throws -> Value
}

// MARK: Boolean Conversions

///// A failure to convert an Automerge scalar value to or from a Boolean representation.
// public enum BooleanScalarConversionError: LocalizedError {
//    case notbool(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notbool(val):
//            return "Failed to read the scalar value \(val) as a Boolean."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

public enum ValueConversionError: LocalizedError {
    case notBooleanScalarValue(Value)
    case notStringScalarValue(Value)
    case notDateScalarValue(Value)
    case notUIntScalarValue(Value)
    case notIntScalarValue(Value)
    case notDoubleScalarValue(Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notBooleanScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as a Boolean."
        case let .notStringScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as a String."
        case let .notDateScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as Data."
        case let .notUIntScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as an UInt."
        case let .notIntScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as an Int."
        case let .notDoubleScalarValue(val):
            return "Failed to read the value \(val.debugDescription) as an Int."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Bool: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Self {
        switch val {
        case let .Scalar(.Boolean(b)):
            return b
        default:
            throw ValueConversionError.notBooleanScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.Boolean(self))
    }
}

// MARK: String Conversions

///// A failure to convert an Automerge scalar value to or from a String representation.
// public enum StringScalarConversionError: LocalizedError {
//    case notstring(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notstring(val):
//            return "Failed to read the scalar value \(val) as a String."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension String: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> String {
        switch val {
        case let .Scalar(.String(s)):
            return s
        default:
            throw ValueConversionError.notStringScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.String(self))
    }
}

// MARK: Bytes Conversions

///// A failure to convert an Automerge scalar value to or from a byte representation.
// public enum BytesScalarConversionError: LocalizedError {
//    case notbytes(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notbytes(val):
//            return "Failed to read the scalar value \(val) as a bytes."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension Data: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Data {
        switch val {
        case let .Scalar(.Bytes(d)):
            return d
        default:
            throw ValueConversionError.notDateScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) throws -> Value {
        .Scalar(.Bytes(self))
    }
}

// MARK: UInt Conversions

///// A failure to convert an Automerge scalar value to or from an unsigned integer representation.
// public enum UIntScalarConversionError: LocalizedError {
//    case notUInt(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notUInt(val):
//            return "Failed to read the scalar value \(val) as an unsigned integer."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension UInt: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> UInt {
        switch val {
        case let .Scalar(.Uint(d)):
            return UInt(d)
        default:
            throw ValueConversionError.notUIntScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.Uint(UInt64(self)))
    }
}

// MARK: Int Conversions

///// A failure to convert an Automerge scalar value to or from a signed integer representation.
// public enum IntScalarConversionError: LocalizedError {
//    case notInt(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notInt(val):
//            return "Failed to read the scalar value \(val) as a signed integer."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension Int: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Int {
        switch val {
        case let .Scalar(.Int(d)):
            return Int(d)
        default:
            throw ValueConversionError.notIntScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.Int(Int64(self)))
    }
}

// MARK: Double Conversions

///// A failure to convert an Automerge scalar value to or from a 64-bit floating-point value representation.
// public enum DoubleScalarConversionError: LocalizedError {
//    case notDouble(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notDouble(val):
//            return "Failed to read the scalar value \(val) as a 64-bit floating-point value."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension Double: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Double {
        switch val {
        case let .Scalar(.F64(d)):
            return Double(d)
        default:
            throw ValueConversionError.notDoubleScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.F64(self))
    }
}

// MARK: Timestamp Conversions

///// A failure to convert an Automerge scalar value to or from a timestamp representation.
// public enum TimestampScalarConversionError: LocalizedError {
//    case notTimetamp(_ val: Value)
//
//    /// A localized message describing what error occurred.
//    public var errorDescription: String? {
//        switch self {
//        case let .notTimetamp(val):
//            return "Failed to read the scalar value \(val) as a timestamp value."
//        }
//    }
//
//    /// A localized message describing the reason for the failure.
//    public var failureReason: String? { nil }
// }

extension Date: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Date {
        switch val {
        case let .Scalar(.Timestamp(d)):
            return d
        default:
            throw ValueConversionError.notDateScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.Timestamp(self))
    }
}

extension Counter: AutomergeRepresentable {
    public static func fromValue(_ val: Value) throws -> Counter {
        switch val {
        case let .Scalar(.Counter(d)):
            return Counter(Int(d))
        default:
            throw ValueConversionError.notIntScalarValue(val)
        }
    }

    public func toValue(doc _: Document, objId _: ObjId) -> Value {
        .Scalar(.Counter(Int64(value)))
    }
}
