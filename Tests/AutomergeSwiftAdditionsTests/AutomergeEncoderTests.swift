//
//  AutomergeEncoderImpl+RetrieveTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 5/16/23.
//

import Automerge
import AutomergeSwiftAdditions
import XCTest

final class AutomergeEncoderTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list

        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        setupCache["nestedMap"] = nestedMap

        try! doc.put(obj: nestedMap, key: "image", value: .Bytes(Data()))
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        setupCache["deeplyNestedText"] = deeplyNestedText
    }

    func testSimpleKeyEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
        }
        let automergeEncoder = AutomergeEncoder(doc: doc)

        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)

        let sample = SimpleStruct(
            name: "henry",
            duration: 3.14159,
            flag: true,
            count: 5,
            date: earlyDate,
            data: Data("hello".utf8),
            uuid: UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!
        )

        try automergeEncoder.encode(sample)

        if case let .Scalar(.String(a_name)) = try doc.get(obj: ObjId.ROOT, key: "name") {
            XCTAssertEqual(a_name, "henry")
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "name")))")
        }

        if case let .Scalar(.F64(duration_value)) = try doc.get(obj: ObjId.ROOT, key: "duration") {
            XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "duration")))")
        }

        if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: ObjId.ROOT, key: "flag") {
            XCTAssertEqual(boolean_value, true)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "flag")))")
        }

        if case let .Scalar(.Int(int_value)) = try doc.get(obj: ObjId.ROOT, key: "count") {
            XCTAssertEqual(int_value, 5)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "count")))")
        }

        if case let .Scalar(.Timestamp(timestamp_value)) = try doc.get(obj: ObjId.ROOT, key: "date") {
            XCTAssertEqual(timestamp_value, -905182980)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "date")))")
        }

        // try debugPrint(doc.get(obj: ObjId.ROOT, key: "data") as Any)
        if case let .Scalar(.Bytes(data_value)) = try doc.get(obj: ObjId.ROOT, key: "data") {
            XCTAssertEqual(data_value, Data("hello".utf8))
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "data")))")
        }

        // debugPrint(try doc.get(obj: ObjId.ROOT, key: "uuid"))
        if case let .Scalar(.String(uuid_string)) = try doc.get(obj: ObjId.ROOT, key: "uuid") {
            XCTAssertEqual(uuid_string, "99CEBB16-1062-4F21-8837-CF18EC09DCD7")
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "uuid")))")
        }
    }

    func testNestedKeyEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
        }

        struct RootModel: Codable {
            let example: SimpleStruct
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)

        let sample = RootModel(example: SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5))

        try automergeEncoder.encode(sample)

        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "example") {
            XCTAssertEqual(container_type, ObjType.Map)

            if case let .Scalar(.String(a_name)) = try doc.get(obj: container_id, key: "name") {
                XCTAssertEqual(a_name, "henry")
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "name")))")
            }

            if case let .Scalar(.F64(duration_value)) = try doc.get(obj: container_id, key: "duration") {
                XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "duration")))")
            }

            if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: container_id, key: "flag") {
                XCTAssertEqual(boolean_value, true)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "flag")))")
            }

            if case let .Scalar(.Int(int_value)) = try doc.get(obj: container_id, key: "count") {
                XCTAssertEqual(int_value, 5)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "count")))")
            }
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "example")))")
        }
    }

    func testNestedListEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
        }

        struct RootModel: Codable {
            let example: [SimpleStruct]
        }
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        let sample = RootModel(example: [SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5)])

        try automergeEncoder.encode(sample)

        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "example") {
            XCTAssertEqual(container_type, ObjType.List)

            if case let .Object(firstListItem, first_list_type) = try doc.get(obj: container_id, index: 0) {
                XCTAssertEqual(first_list_type, ObjType.Map)

                if case let .Scalar(.String(a_name)) = try doc.get(obj: firstListItem, key: "name") {
                    XCTAssertEqual(a_name, "henry")
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "name")))")
                }

                if case let .Scalar(.F64(duration_value)) = try doc.get(obj: firstListItem, key: "duration") {
                    XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "duration")))")
                }

                if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: firstListItem, key: "flag") {
                    XCTAssertEqual(boolean_value, true)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "flag")))")
                }

                if case let .Scalar(.Int(int_value)) = try doc.get(obj: firstListItem, key: "count") {
                    XCTAssertEqual(int_value, 5)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "count")))")
                }
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, index: 0)))")
            }
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "example")))")
        }
    }
}
