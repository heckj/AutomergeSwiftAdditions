//
//  AutomergeEncoderImpl+RetrieveTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 5/16/23.
//

import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

final class AutomergeKeyEncoderImplTests: XCTestCase {
    var doc: Document!
    var rootKeyedContainer: KeyedEncodingContainer<AutomergeKeyEncoderImplTests.SampleCodingKeys>!
    enum SampleCodingKeys: String, CodingKey {
        case value
    }

    override func setUp() {
        doc = Document()
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [],
            doc: doc,
            strategy: .createWhenNeeded
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
    }

    func testSimpleKeyEncode_Bool() throws {
        try rootKeyedContainer.encode(true, forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Boolean(true)))
    }

    func testSimpleKeyEncode_Float() throws {
        try rootKeyedContainer.encode(Float(4.3), forKey: .value)
        if case let .Scalar(.F64(floatValue)) = try doc.get(obj: ObjId.ROOT, key: "value") {
            XCTAssertEqual(floatValue, 4.3, accuracy: 0.01)
        } else {
            XCTFail("Scalar Float value not retrieved.")
        }
    }

    func testErrorEncode_Float() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Float(3.4), forKey: .value))
    }

    func testSimpleKeyEncode_InvalidFloat() throws {
        XCTAssertThrowsError(
            try rootKeyedContainer.encode(Float.infinity, forKey: .value)
        )
    }

    func testSimpleKeyEncode_InvalidDouble() throws {
        XCTAssertThrowsError(
            try rootKeyedContainer.encode(Double.nan, forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int8() throws {
        try rootKeyedContainer.encode(Int8(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))
    }

    func testSimpleKeyEncode_Int16() throws {
        try rootKeyedContainer.encode(Int16(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))
    }

    func testSimpleKeyEncode_Int32() throws {
        try rootKeyedContainer.encode(Int32(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))
    }

    func testSimpleKeyEncode_Int64() throws {
        try rootKeyedContainer.encode(Int64(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))
    }

    func testSimpleKeyEncode_UInt() throws {
        try rootKeyedContainer.encode(UInt(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
    }

    func testSimpleKeyEncode_UInt8() throws {
        try rootKeyedContainer.encode(UInt8(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
    }

    func testSimpleKeyEncode_UInt16() throws {
        try rootKeyedContainer.encode(UInt16(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
    }

    func testSimpleKeyEncode_UInt32() throws {
        try rootKeyedContainer.encode(UInt32(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
    }

    func testSimpleKeyEncode_UInt64() throws {
        try rootKeyedContainer.encode(UInt64(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
    }

    // NEED TO MAKE COUNTER conform to Codable
//    func testSimpleKeyEncode_Counter() throws {
//        try rootKeyedContainer.encode(Counter(4), forKey: .value)
//        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
//    }

    func testErrorEncode_Bool() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(true, forKey: .value))
    }

    func testErrorEncode_Double() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Double(8.16), forKey: .value))
    }

    func testErrorEncode_Int() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int(8), forKey: .value))
    }

    func testErrorEncode_Int8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int8(8), forKey: .value))
    }

    func testErrorEncode_Int16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int16(8), forKey: .value))
    }

    func testErrorEncode_Int32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int32(8), forKey: .value))
    }

    func testErrorEncode_Int64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int64(8), forKey: .value))
    }

    func testErrorEncode_UInt() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt(8), forKey: .value))
    }

    func testErrorEncode_UInt8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt8(8), forKey: .value))
    }

    func testErrorEncode_UInt16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt16(8), forKey: .value))
    }

    func testErrorEncode_UInt32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt32(8), forKey: .value))
    }

    func testErrorEncode_UInt64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt64(8), forKey: .value))
    }

    func testErrorEncode_Codable() throws {
        struct SimpleStruct: Codable {
            let a: String
        }

        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(SimpleStruct(a: "foo"), forKey: .value))
    }

    func testSuperEncoder() throws {
        let enc = rootKeyedContainer.superEncoder()
        XCTAssertEqual(enc.codingPath.count, 0)
    }

    func testSuperEncoderForKey() throws {
        let enc = rootKeyedContainer.superEncoder(forKey: .value)
        XCTAssertEqual(enc.codingPath.count, 0)
    }
}
