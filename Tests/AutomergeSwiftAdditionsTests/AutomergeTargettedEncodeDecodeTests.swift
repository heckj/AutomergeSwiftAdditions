import Automerge
import AutomergeSwiftAdditions
import XCTest

final class AutomergeTargettedEncodeDecodeTests: XCTestCase {
    var doc: Document!

    override func setUp() {
        doc = Document()
    }

    func testSimpleKeyEncode() throws {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let notes: Text
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)
        let automergeDecoder = AutomergeDecoder(doc: doc)

        let sample = SimpleStruct(
            name: "henry",
            notes: Text("Something wicked this way comes.")
        )

        let pathToTry: [AnyCodingKey] = [
            AnyCodingKey("example"),
            AnyCodingKey(0),
        ]
        try automergeEncoder.encode(sample, at: pathToTry)

        XCTAssertNotNil(try doc.get(obj: ObjId.ROOT, key: "example"))
        let foo = try doc.lookupPath(path: ".example.[0]")
        XCTAssertNotNil(foo)

        let decodedStruct = try automergeDecoder.decode(SimpleStruct.self, from: pathToTry)
        XCTAssertEqual(decodedStruct, sample)
    }

    func testTargetedSingleValueDecode() throws {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let notes: Text
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)
        let automergeDecoder = AutomergeDecoder(doc: doc)

        let sample = SimpleStruct(
            name: "henry",
            notes: Text("Something wicked this way comes.")
        )

        let pathToTry: [AnyCodingKey] = [
            AnyCodingKey("example"),
            AnyCodingKey(0),
        ]
        try automergeEncoder.encode(sample, at: pathToTry)

        let decoded1 = try automergeDecoder.decode(String.self, from: AnyCodingKey.parsePath("example.[0].name"))
        XCTAssertEqual(decoded1, "henry")

        let decoded2 = try automergeDecoder.decode(Text.self, from: AnyCodingKey.parsePath("example.[0].notes"))
        XCTAssertEqual(decoded2.value, "Something wicked this way comes.")
    }

    func testTargetedDecodeOfData() throws {
        let exampleData = Data("Hello".utf8)
        try doc.put(obj: ObjId.ROOT, key: "data", value: .Bytes(exampleData))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedData = try automergeDecoder.decode(Data.self, from: [AnyCodingKey("data")])
        XCTAssertEqual(decodedData, exampleData)
    }

    func testTargetedDecodeOfDate() throws {
        let exampleDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)
        try doc.put(obj: ObjId.ROOT, key: "date", value: .Timestamp(-905182980))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedDate = try automergeDecoder.decode(Date.self, from: [AnyCodingKey("date")])
        XCTAssertEqual(decodedDate, exampleDate)
    }

    func testTargetedDecodeOfCounter() throws {
        let exampleCounter = Counter(342)
        try doc.put(obj: ObjId.ROOT, key: "counter", value: .Counter(342))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedCounter = try automergeDecoder.decode(Counter.self, from: [AnyCodingKey("counter")])
        XCTAssertEqual(decodedCounter, exampleCounter)
    }
}
