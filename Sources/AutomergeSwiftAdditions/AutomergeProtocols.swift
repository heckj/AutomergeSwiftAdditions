import Combine

import class Automerge.Document
import struct Automerge.ObjId
import enum Automerge.ScalarValue

/// A type that has a reference to an Automerge document.
public protocol HasDoc {
    /// The reference to an Automerge document.
    var doc: Document { get }
}

/// A type that may have a reference to the Id of a container in an Automerge document.
public protocol HasObj {
    /// The optional reference to a container within an Automerge document.
    var obj: ObjId? { get }

    /// Returns a Boolean value that indicates whether it has a reference to a container within an Automerge document.
    /// - Returns: True, if the object Id reference isn't nil, otherwise false.
    func isBound() -> Bool
}

// default implementation for bound/unbound
public extension HasObj {
    /// Returns a Boolean value that indicates whether it has a reference to a container within an Automerge document.
    /// - Returns: True, if the object Id reference isn't nil, otherwise false.
    func isBound() -> Bool {
        obj != nil
    }
}

/// A type that represents an observable Automerge container.
public protocol ObservableAutomergeContainer: ObservableObject, HasDoc, HasObj {
    /// A publisher that provides a signal that indicates the container object is about to change.
    var objectWillChange: ObservableObjectPublisher { get }
    // By using the type `ObservableObjectPublisher`, the conforming type can
    // more easily invoke a send() through a generics reference.

    var unboundStorage: [String: ScalarValue] { get set }

    /// Creates a new instance of this type.
    /// - Parameters:
    ///   - doc: The Automerge document from which the type reflects data.
    ///   - obj: The container within the Automerge document from which the type reflects data.
    init(doc: Document, obj: ObjId?)
}
