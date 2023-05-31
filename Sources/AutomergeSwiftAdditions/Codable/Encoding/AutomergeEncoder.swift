import class Automerge.Document

public struct AutomergeEncoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    var doc: Document
    var schemaStrategy: SchemaStrategy

    public init(doc: Document, strategy: SchemaStrategy = .default) {
        self.doc = doc
        self.schemaStrategy = strategy
    }

    public func encode<T: Encodable>(_ value: T) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: [],
            doc: self.doc
        )
        try value.encode(to: encoder)
    }
}
