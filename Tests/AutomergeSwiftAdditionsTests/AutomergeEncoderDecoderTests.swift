//
//  AutomergeEncoderImpl+RetrieveTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 5/16/23.
//

import Automerge
import AutomergeSwiftAdditions
import XCTest

final class AutomergeEncoderDecoderTests: XCTestCase {
    var doc: Document!

    override func setUp() {
        doc = Document()
    }

    func testSimpleEncodeDecode() throws {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
            let notes: Text
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)

        let sample = SimpleStruct(
            name: "henry",
            duration: 3.14159,
            flag: true,
            count: 5,
            date: earlyDate,
            data: Data("hello".utf8),
            uuid: UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!,
            notes: Text("Something wicked this way comes.")
        )

        try encoder.encode(sample)
        let decodedStruct = try decoder.decode(SimpleStruct.self)

        XCTAssertEqual(sample, decodedStruct)
    }

    func testListOfSimpleEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [SimpleStruct]
        }

        struct SimpleStruct: Codable, Equatable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
            let notes: Text
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)

        let sample = SimpleStruct(
            name: "henry",
            duration: 3.14159,
            flag: true,
            count: 5,
            date: earlyDate,
            data: Data("hello".utf8),
            uuid: UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!,
            notes: Text("Something wicked this way comes.")
        )
        let topLevel = WrapperStruct(list: [sample])

        try encoder.encode(topLevel)

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(sample, decodedStruct.list.first)
    }

    func testListOfFloatEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Float]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3.0])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3.0, decodedStruct.list.first!, accuracy: 0.1)
    }

    func testListOfDoubleEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Float]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3.0])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3.0, decodedStruct.list.first!, accuracy: 0.1)
    }

    func testListOfInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int8]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int16]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int32]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int64]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt8]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt16]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt32]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt64]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfDateEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Date]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)
        let topLevel = WrapperStruct(list: [earlyDate])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(earlyDate, decodedStruct.list.first)
    }

    func testListOfDataEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Data]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let topLevel = WrapperStruct(list: [Data("Hello".utf8)])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(Data("Hello".utf8), decodedStruct.list.first)
    }

//    func testListOfTextEncodeDecode() throws {
//        struct WrapperStruct: Codable, Equatable {
//            let list: [Text]
//        }
//
//        let encoder = AutomergeEncoder(doc: doc)
//        let decoder = AutomergeDecoder(doc: doc)
//
//        let topLevel = WrapperStruct(list: [Text("hi")])
//
//        try encoder.encode(topLevel)
//        let decodedStruct = try decoder.decode(WrapperStruct.self)
//        XCTAssertEqual(decodedStruct.list.count, 1)
//        XCTAssertEqual("hi", decodedStruct.list.first?.description)
//    }
}
