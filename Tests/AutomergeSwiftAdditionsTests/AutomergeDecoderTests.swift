//
//  AutomergeEncoderImpl+RetrieveTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 5/16/23.
//

import Automerge
import AutomergeSwiftAdditions
import XCTest

final class AutomergeDecoderTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
        
        try! doc.put(obj: ObjId.ROOT, key: "name", value: .String("Joe"))
        try! doc.put(obj: ObjId.ROOT, key: "duration", value: .F64(3.14159))
        try! doc.put(obj: ObjId.ROOT, key: "flag", value: .Boolean(true))
        try! doc.put(obj: ObjId.ROOT, key: "count", value: .Int(5))
        
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "notes", ty: .Text)
        setupCache["notes"] = text
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello")

        let votes = try! doc.putObject(obj: ObjId.ROOT, key: "votes", ty: .List)
        setupCache["votes"] = votes
        try! doc.insert(obj: votes, index: 0, value: .Int(3))
        try! doc.insert(obj: votes, index: 1, value: .Int(4))
        try! doc.insert(obj: votes, index: 2, value: .Int(5))
        
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list

        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        setupCache["nestedMap"] = nestedMap

        try! doc.put(obj: nestedMap, key: "image", value: .Bytes(Data()))
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        setupCache["deeplyNestedText"] = deeplyNestedText
    }

    func testSimpleKeyDecode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            //            let date: Date
            //            let data: Data
            //            let uuid: UUID
            //            let notes: Text
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertNoThrow(try decoder.decode(SimpleStruct.self))

        let decodedStruct = try decoder.decode(SimpleStruct.self)
        
        XCTAssertEqual(decodedStruct.name, "Joe")
        XCTAssertEqual(decodedStruct.duration, 3.14159, accuracy: 0.0001)
        XCTAssertTrue(decodedStruct.flag)
        XCTAssertEqual(decodedStruct.count, 5)
    }
    
    func testKeyAndListDecode() throws {
        struct StructWithArray: Codable {
            let name: String
            let votes: [Int]
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertNoThrow(try decoder.decode(StructWithArray.self))

        let decodedStruct = try decoder.decode(StructWithArray.self)
        
        XCTAssertEqual(decodedStruct.name, "Joe")
        XCTAssertEqual(decodedStruct.votes, [3,4,5])
    }
}
