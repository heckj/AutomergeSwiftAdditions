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
    
    func testSimpleEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
        }
        let automergeEncoder = AutomergeEncoder(doc: self.doc)
        
        let sample = SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5)
        try automergeEncoder.encode(sample)
                
        if case let .Scalar(.String(a_name)) = try doc.get(obj: ObjId.ROOT, key: "name") {
            XCTAssertEqual(a_name, "henry")
        } else {
            XCTFail("Didn't find: \(String(describing: try doc.get(obj: ObjId.ROOT, key: "name")))")
        }
        
        if case let .Scalar(.F64(duration_value)) = try doc.get(obj: ObjId.ROOT, key: "duration") {
            XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
        } else {
            XCTFail("Didn't find: \(String(describing: try doc.get(obj: ObjId.ROOT, key: "duration")))")
        }

        if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: ObjId.ROOT, key: "flag") {
            XCTAssertEqual(boolean_value, true)
        } else {
            XCTFail("Didn't find: \(String(describing: try doc.get(obj: ObjId.ROOT, key: "flag")))")
        }

        if case let .Scalar(.Int(int_value)) = try doc.get(obj: ObjId.ROOT, key: "count") {
            XCTAssertEqual(int_value, 5)
        } else {
            XCTFail("Didn't find: \(String(describing: try doc.get(obj: ObjId.ROOT, key: "count")))")
        }
    }
    
    func testNestedEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
        }
        
        struct RootModel: Codable {
            let example: SimpleStruct
            
        }

        let automergeEncoder = AutomergeEncoder(doc: self.doc)
        
        let sample = RootModel(example: SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5))
        
        try automergeEncoder.encode(sample)
                
        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "example") {
            XCTAssertEqual(container_type, ObjType.Map)
            
            
            if case let .Scalar(.String(a_name)) = try doc.get(obj: container_id, key: "name") {
                XCTAssertEqual(a_name, "henry")
            } else {
                XCTFail("Didn't find: \(String(describing: try doc.get(obj: container_id, key: "name")))")
            }
            
            if case let .Scalar(.F64(duration_value)) = try doc.get(obj: container_id, key: "duration") {
                XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
            } else {
                XCTFail("Didn't find: \(String(describing: try doc.get(obj: container_id, key: "duration")))")
            }

            if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: container_id, key: "flag") {
                XCTAssertEqual(boolean_value, true)
            } else {
                XCTFail("Didn't find: \(String(describing: try doc.get(obj: container_id, key: "flag")))")
            }

            if case let .Scalar(.Int(int_value)) = try doc.get(obj: container_id, key: "count") {
                XCTAssertEqual(int_value, 5)
            } else {
                XCTFail("Didn't find: \(String(describing: try doc.get(obj: container_id, key: "count")))")
            }
        } else {
            XCTFail("Didn't find: \(String(describing: try doc.get(obj: ObjId.ROOT, key: "example")))")
        }
        
    }
}
