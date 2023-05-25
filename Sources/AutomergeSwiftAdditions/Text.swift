import Foundation

/// A type that presents a string backed by a Sequential CRDT
public struct Text: Hashable, Codable {
    var value: String

    // NOTE(heckj): In the near future, we'll have Automerge support for Peritext,
    // which should map pretty well to AttributedStrings. At that point, this struct
    // would make a lot more sense exposing an AttributedString by default, with an
    // optional "slimmed down" regular String from it.

    /// Creates a new Text instance with the string value you provide.
    /// - Parameter value: The value for the text.
    public init(_ value: String) {
        self.value = value
    }
}

extension Text: CustomStringConvertible {
    public var description: String {
        value
    }
}
