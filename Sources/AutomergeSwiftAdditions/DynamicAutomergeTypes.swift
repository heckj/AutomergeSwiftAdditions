import Combine
import Foundation

import class Automerge.Document
import struct Automerge.ObjId
import enum Automerge.ScalarValue

// MARK: Automerge 'List' overlays

class DynamicAutomergeList: ObservableAutomergeContainer, Sequence, RandomAccessCollection {
    var unboundStorage: [String: Automerge.ScalarValue]
    var doc: Document
    var obj: ObjId?

    required init(doc: Document, obj: ObjId?) {
        if obj != nil {
            precondition(obj != ObjId.ROOT, "A list object can't be bound to the Root of an Automerge document.")
            precondition(doc.objectType(obj: obj!) == .List, "The object with id: \(obj!) is not a List CRDT.")
        }
        self.doc = doc
        self.obj = obj
        unboundStorage = [:]
    }

    init?(doc: Document, path: String) throws {
        self.doc = doc
        if let objId = try doc.lookupPath(path: path), doc.objectType(obj: objId) == .List {
            obj = objId
            unboundStorage = [:]
        } else {
            return nil
        }
    }

    init?(doc: Document, _ automergeType: UnifiedAutomergeEnumType) throws {
        self.doc = doc
        if case let .List(objId) = automergeType {
            obj = objId
            unboundStorage = [:]
        } else {
            return nil
        }
    }

    // MARK: DynamicAutomergeList Sequence Conformance

    typealias Element = UnifiedAutomergeEnumType?

    /// Returns an iterator over the elements of this sequence.
    func makeIterator() -> AmListIterator<Element> {
        AmListIterator(doc: doc, objId: obj)
    }

    struct AmListIterator<Element>: IteratorProtocol {
        private let doc: Document
        private let objId: ObjId?
        private var cursorIndex: UInt64
        private let length: UInt64

        init(doc: Document, objId: ObjId?) {
            self.doc = doc
            self.objId = objId
            cursorIndex = 0
            if objId != nil {
                length = doc.length(obj: objId!)
            } else {
                length = 0
            }
        }

        mutating func next() -> Element? {
            if cursorIndex >= length || objId == nil {
                return nil
            }
            cursorIndex += 1
            if let result = try! doc.get(obj: objId!, index: cursorIndex) {
                do {
                    return try result.automergeType as? Element
                } catch {
                    // yes, we're really swallowing any underlying errors.
                }
            }
            return nil
        }
    }

    // MARK: DynamicAutomergeList RandomAccessCollection Conformance

    // typealias Index = UInt64 // inferred
    typealias Iterator = AmListIterator<Element>

    var startIndex: UInt64 {
        0
    }

    func index(after i: UInt64) -> UInt64 {
        i + 1
    }

    func index(before i: UInt64) -> UInt64 {
        i - 1
    }

    var endIndex: UInt64 {
        guard let objId = obj else {
            return 0
        }
        return doc.length(obj: objId)
    }

    subscript(position: UInt64) -> UnifiedAutomergeEnumType? {
        do {
            if let objId = obj, let amvalue = try doc.get(obj: objId, index: position) {
                return try amvalue.automergeType
            }
        } catch {
            // swallow errors to return nil
        }
        return nil
    }
}

// MARK: Automerge 'Map' overlays

class DynamicAutomergeMap: ObservableAutomergeContainer, Sequence, Collection {
    var doc: Document
    var obj: ObjId?
    private var _keys: [String]
    var unboundStorage: [String: Automerge.ScalarValue]

    required init(doc: Document, obj: ObjId?) {
        self.doc = doc
        self.obj = obj
        unboundStorage = [:]
        if obj != nil {
            _keys = doc.keys(obj: obj!)
            precondition(doc.objectType(obj: obj!) == .Map, "The object with id: \(obj!) is not a Map CRDT.")
        } else {
            _keys = []
        }
    }

    init?(doc: Document, path: String) throws {
        self.doc = doc
        if let objId = try doc.lookupPath(path: path), doc.objectType(obj: objId) == .Map {
            obj = objId
            unboundStorage = [:]
            _keys = doc.keys(obj: objId)
        } else {
            return nil
        }
    }

    init?(doc: Document, _ automergeType: UnifiedAutomergeEnumType) throws {
        self.doc = doc
        if case let .Map(objId) = automergeType {
            obj = objId
            unboundStorage = [:]
            _keys = doc.keys(obj: objId)
        } else {
            return nil
        }
    }

    // MARK: DynamicAutomergeMap Sequence Conformance

    // public typealias Element = (key: Key, value: Value)
    typealias Element = (String, UnifiedAutomergeEnumType?)

    /// Returns an iterator over the elements of this sequence.
    func makeIterator() -> AmMapIterator<Element> {
        AmMapIterator(doc: doc, objId: obj)
    }

    struct AmMapIterator<Element>: IteratorProtocol {
        private let doc: Document
        private let objId: ObjId?
        private var cursorIndex: UInt64
        private let keys: [String]
        private let length: UInt64

        init(doc: Document, objId: ObjId?) {
            self.doc = doc
            self.objId = objId
            cursorIndex = 0
            if objId != nil {
                length = doc.length(obj: objId!)
                keys = doc.keys(obj: objId!)
            } else {
                length = 0
                keys = []
            }
        }

        mutating func next() -> Element? {
            if cursorIndex >= length, objId != nil {
                return nil
            }
            cursorIndex += 1
            let currentKey = keys[Int(cursorIndex)]
            if let result = try! doc.get(obj: objId!, key: currentKey) {
                do {
                    let amrep = try result.automergeType
                    return (currentKey, amrep) as? Element
                } catch {
                    // yes, we're really swallowing any underlying errors.
                }
            }
            return nil
        }
    }

    // MARK: DynamicAutomergeMap Collection Conformance

    // typealias Index = Int // inferred
    typealias Iterator = AmMapIterator<Element>

    var startIndex: Int {
        0
    }

    var endIndex: Int {
        _keys.count
    }

    func index(after i: Int) -> Int {
        i + 1
    }

    subscript(position: Int) -> (String, UnifiedAutomergeEnumType?) {
        let currentKey = _keys[position]
        if let objId = obj, let result = try! doc.get(obj: objId, key: currentKey) {
            do {
                let amrep = try result.automergeType
                return (currentKey, amrep)
            } catch {
                // yes, we're really swallowing any underlying errors.
            }
        }
        return (currentKey, nil)
    }
}

@dynamicMemberLookup
class DynamicAutomergeObject: ObservableAutomergeContainer {
    var doc: Document
    var obj: ObjId?
    var unboundStorage: [String: Automerge.ScalarValue]

    // alternate initializer that accepts a path into the Automerge document
    required init(doc: Document, obj: ObjId? = ObjId.ROOT) {
        if obj != nil {
            precondition(doc.objectType(obj: obj!) == .Map, "The object with id: \(obj!) is not a Map CRDT.")
        }
        self.doc = doc
        self.obj = obj
        self.unboundStorage = [:]
    }

    init?(doc: Document, path: String) throws {
        self.doc = doc
        if let objId = try doc.lookupPath(path: path) {
            self.obj = objId
            self.unboundStorage = [:]
        } else {
            return nil
        }
    }

    init?(doc: Document, _ automergeType: UnifiedAutomergeEnumType) throws {
        self.doc = doc
        if case let .Map(objId) = automergeType {
            self.obj = objId
            self.unboundStorage = [:]
        } else {
            return nil
        }
    }

    subscript(dynamicMember member: String) -> UnifiedAutomergeEnumType? {
        do {
            if let objId = obj, let amValue = try doc.get(obj: objId, key: member) {
                return try amValue.automergeType
            }
        } catch {
            // yes, we're really swallowing any underlying errors.
        }
        return nil
    }
}
