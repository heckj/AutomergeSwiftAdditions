import struct Automerge.Counter
import class Automerge.Document
import struct Automerge.ObjId
import protocol Automerge.ScalarValueRepresentable
import Foundation

struct AutomergeSingleValueEncodingContainer: SingleValueEncodingContainer {
    let impl: AutomergeEncoderImpl
    let codingPath: [CodingKey]
    let document: Document
    /// The objectId that this keyed encoding container maps to within an Automerge document.
    ///
    /// If `document` is `nil`, the error attempting to retrieve should be in ``lookupError``.
    let objectId: ObjId?
    let codingkey: AnyCodingKey?
    /// An error captured when attempting to look up or create an objectId in Automerge based on the coding path
    /// provided.
    let lookupError: Error?

    private var firstValueWritten: Bool = false

    init(impl: AutomergeEncoderImpl, codingPath: [CodingKey], doc: Document) {
        self.impl = impl
        self.codingPath = codingPath
        self.document = doc
        switch impl.retrieveObjectId(path: codingPath, containerType: .Value) {
        case let .success((objId, codingkey)):
            self.objectId = objId
            self.codingkey = codingkey
            self.lookupError = nil
        case let .failure(capturedError):
            self.objectId = nil
            self.codingkey = nil
            self.lookupError = capturedError
        }
        tracePrint("Establishing Single Value Encoding Container for path \(codingPath.map { AnyCodingKey($0) }))")
    }

    mutating func encodeNil() throws {}

    mutating func encode(_ value: Bool) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .bool(value)
    }

    mutating func encode(_ value: Int) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: Int8) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: Int16) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: Int32) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: Int64) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(value)
    }

    mutating func encode(_ value: UInt) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: UInt8) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: UInt16) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: UInt32) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: UInt64) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .int(Int64(truncatingIfNeeded: value))
    }

    mutating func encode(_ value: Float) throws {
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: self.codingPath,
                debugDescription: "Unable to encode Float.\(value) directly in Automerge."
            ))
        }

        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .double(Double(value))
    }

    mutating func encode(_ value: Double) throws {
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: self.codingPath,
                debugDescription: "Unable to encode Double.\(value) directly in Automerge."
            ))
        }

        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .double(value)
    }

    mutating func encode(_ value: String) throws {
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .string(value)
    }

    mutating func encode(_ value: Data) throws {
        // likely not caught
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .bytes(value)
    }

    mutating func encode(_ value: Counter) throws {
        // likely not caught
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .counter(Int64(value.value))
    }

    mutating func encode(_ value: Date) throws {
        // likely not caught
        try self.scalarValueEncode(value: value)
        self.impl.singleValue = .timestamp(Int64(value.timeIntervalSince1970))
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        self.preconditionCanEncodeNewValue()
        guard let objectId = self.objectId else {
            throw reportBestError()
        }
        switch T.self {
        case is Date.Type:
            // Capture and override the default encodable pathing for Date since
            // Automerge supports it as a primitive value type.
            let downcastDate = value as! Date
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .noPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            if let indexToWrite = codingkey.intValue {
                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: downcastDate.toScalarValue())
            } else {
                try document.put(obj: objectId, key: codingkey.stringValue, value: downcastDate.toScalarValue())
            }
        case is Data.Type:
            // Capture and override the default encodable pathing for Data since
            // Automerge supports it as a primitive value type.
            let downcastData = value as! Data
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .noPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            if let indexToWrite = codingkey.intValue {
                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: downcastData.toScalarValue())
            } else {
                try document.put(obj: objectId, key: codingkey.stringValue, value: downcastData.toScalarValue())
            }
        case is Counter.Type:
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            let downcastCounter = value as! Counter
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .noPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            if let indexToWrite = codingkey.intValue {
                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: downcastCounter.toScalarValue())
            } else {
                try document.put(obj: objectId, key: codingkey.stringValue, value: downcastCounter.toScalarValue())
            }
        case is Text.Type:
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .noPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            let downcastText = value as! Text
            // FIXME: check to see if the object exists here before just splatting a new one into place

            let textNode: ObjId
            if let indexToWrite = codingkey.intValue {
                textNode = try document.putObject(obj: objectId, index: UInt64(indexToWrite), ty: .Text)
            } else {
                textNode = try document.putObject(obj: objectId, key: codingkey.stringValue, ty: .Text)
            }

            // Iterate through
            let currentText = try! document.text(obj: textNode).utf8
            let diff: CollectionDifference<String.UTF8View.Element> = downcastText.value.utf8
                .difference(from: currentText)
            for change in diff {
                switch change {
                case let .insert(offset, element, _):
                    let char = String(bytes: [element], encoding: .utf8)
                    try document.spliceText(obj: textNode, start: UInt64(offset), delete: 0, value: char)
                case let .remove(offset, _, _):
                    try document.spliceText(obj: textNode, start: UInt64(offset), delete: 1)
                }
            }
        default:
            try value.encode(to: self.impl)
        }
    }

    private func scalarValueEncode(value: some ScalarValueRepresentable) throws {
        self.preconditionCanEncodeNewValue()
        guard let objectId = self.objectId, let codingkey = self.codingkey else {
            throw reportBestError()
        }
        if let indexToWrite = codingkey.intValue {
            try document.insert(obj: objectId, index: UInt64(indexToWrite), value: value.toScalarValue())
        } else {
            try document.put(obj: objectId, key: codingkey.stringValue, value: value.toScalarValue())
        }
    }

    func preconditionCanEncodeNewValue() {
        precondition(
            self.impl.singleValue == nil,
            "Attempt to encode value through single value container when previously value already encoded."
        )
    }

    fileprivate func reportBestError() -> Error {
        // Returns the best value it can from a lookup error scenario.
        if let containerLookupError = self.lookupError {
            return containerLookupError
        } else {
            // If the error wasn't captured for some reason, drop back to a more general error exposing
            // the precondition failure.
            return CodingKeyLookupError
                .unexpectedLookupFailure(
                    "Encoding called on KeyedContainer when ObjectId is nil, and there was no recorded lookup error for the path \(self.codingPath)"
                )
        }
    }
}
