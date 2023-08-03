import Combine
import Foundation

import class Automerge.Document
import struct Automerge.ObjId
import enum Automerge.ScalarValue

open class AutomergeList<T: AutomergeRepresentable>: ObservableAutomergeContainer, Sequence {
    public var doc: Document
    public var obj: ObjId?
    public var unboundStorage: [String: Automerge.ScalarValue] = [:] // un-used, req by ObservableAutomergeContainer
    private var length: UInt64

    public required init(doc: Document, obj: ObjId?) {
        self.doc = doc
        if let obj {
            precondition(obj != ObjId.ROOT, "A list object can't be bound to the Root of an Automerge document.")
            precondition(doc.objectType(obj: obj) == .List, "The object with id: \(obj) is not a List CRDT.")
            self.obj = obj
            length = doc.length(obj: obj)
        } else {
            self.obj = nil
            length = 0
        }
        // TODO: add validation of schema - that all list entries are convertible to type `T`
    }

    public init?(doc: Document, path: String) throws {
        self.doc = doc
        if let objId = try doc.lookupPath(path: path), doc.objectType(obj: objId) == .List {
            obj = objId
            length = doc.length(obj: objId)
            // TODO: add validation of schema - that all list entries are convertible to type `T`
        } else {
            return nil
        }
    }

    // MARK: Sequence Conformance

    /// Returns an iterator over the elements of this sequence.
    public func makeIterator() -> AmListIterator<T> {
        AmListIterator(doc: doc, objId: obj)
    }

    public struct AmListIterator<Element>: IteratorProtocol {
        private let doc: Document
        private let objId: ObjId?
        private var cursorIndex: UInt64
        private let length: UInt64

        init(doc: Document, objId: ObjId?) {
            self.doc = doc
            self.objId = objId
            cursorIndex = 0
            if let objId {
                length = doc.length(obj: objId)
            } else {
                length = 0
            }
        }

        public mutating func next() -> Element? {
            if cursorIndex >= length {
                return nil
            }
            if let objId = objId {
                cursorIndex += 1
                if let result = try! doc.get(obj: objId, index: cursorIndex) {
                    do {
                        return try result.automergeType as? Element
                    } catch {
                        // yes, we're really swallowing any underlying errors.
                    }
                }
            }
            return nil
        }
    }
}

// MARK: AutomergeList<T> RandomAccessCollection Conformance

extension AutomergeList: RandomAccessCollection {
    // TODO: implement MutableAccessCollection
    public typealias Index = UInt64 // inferred
    public typealias Iterator = AmListIterator<T>

    public var startIndex: UInt64 {
        0
    }

    public func index(after i: UInt64) -> UInt64 {
        i + 1
    }

    public func index(before i: UInt64) -> UInt64 {
        i - 1
    }

    public var endIndex: UInt64 {
        length
    }

    public subscript(position: UInt64) -> T {
        do {
            guard let amvalue = try doc.get(obj: obj!, index: position) else {
                fatalError("Unable to access list \(obj!) at index \(position)")
            }
            return try T.fromValue(amvalue)
        } catch {
            fatalError("Unable to convert value: \(error)")
        }
    }
}
