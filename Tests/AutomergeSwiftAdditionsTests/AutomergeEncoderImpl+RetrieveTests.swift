//
//  AutomergeEncoderImpl+RetrieveTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 5/16/23.
//

import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

final class RetrieveObjectIdTests: XCTestCase {
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

    func testPathAtRoot() throws {
        let doc = Document()
        let path = try! doc.path(obj: ObjId.ROOT)
        XCTAssertEqual(path, [])
    }

    func testSetupDocPath() throws {
        let pathToText = try! doc.path(obj: setupCache["deeplyNestedText"]!).stringPath()
        XCTAssertEqual(setupCache.count, 3)
        XCTAssertEqual(pathToText, ".list.[0].notes")
    }

    func testRetrieveLeafValue() throws {
        let fullCodingPath: [AnyCodingKey] = [
            AnyCodingKey("list"),
            AnyCodingKey(0),
            AnyCodingKey("notes"),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: fullCodingPath, containerType: .Value)

        switch result {
        case let .success((objectId, codingKeyInstance)):
            XCTAssertEqual(objectId, setupCache["nestedMap"])
            XCTAssertEqual(codingKeyInstance, AnyCodingKey("notes"))
        case .failure:
            XCTFail("Failure looking up full path to notes as a value")
        }
        // Caching not yet implemented
        // XCTAssertEqual(encoderImpl.cache.count, 2)
    }

    func testCreateSchemaWhereNull() throws {
        let newCodingPath: [AnyCodingKey] = [
            AnyCodingKey("list"),
            AnyCodingKey(1),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: newCodingPath, containerType: .Key)

        switch result {
        case let .success((objectId, codingKeyInstance)):
            XCTAssertEqual(codingKeyInstance, AnyCodingKey.ROOT)
            let pathToNewMap = try! doc.path(obj: objectId).stringPath()
            XCTAssertEqual(pathToNewMap, ".list.[1]")
        case let .failure(err):
            XCTFail("Failure looking up new path location: \(err)")
        }
    }

    func testCreateDeeperNewSchema_Key() throws {
        let newCodingPath: [AnyCodingKey] = [
            AnyCodingKey("redfish"),
            AnyCodingKey(0),
            AnyCodingKey("bluefish"),
            AnyCodingKey("yellowfish"),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: newCodingPath, containerType: .Key)

        switch result {
        case let .success((objectId, codingKeyInstance)):
            XCTAssertEqual(codingKeyInstance, AnyCodingKey.ROOT)
            let pathToNewMap = try! doc.path(obj: objectId).stringPath()
            XCTAssertEqual(pathToNewMap, ".redfish.[0].bluefish.yellowfish")
        case let .failure(err):
            XCTFail("Failure looking up new path location: \(err)")
        }
    }

    func testCreateDeeperNewSchema_List() throws {
        let newCodingPath: [AnyCodingKey] = [
            AnyCodingKey("redfish"),
            AnyCodingKey(0),
            AnyCodingKey("bluefish"),
            AnyCodingKey(0),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: newCodingPath, containerType: .Index)

        switch result {
        case let .success((objectId, codingKeyInstance)):
            XCTAssertEqual(codingKeyInstance, AnyCodingKey.ROOT)
            let pathToNewMap = try! doc.path(obj: objectId).stringPath()
            XCTAssertEqual(pathToNewMap, ".redfish.[0].bluefish.[0]")
        case let .failure(err):
            XCTFail("Failure looking up new path location: \(err)")
        }
    }

    func testCreateDeeperNewSchema_Value() throws {
        let newCodingPath: [AnyCodingKey] = [
            AnyCodingKey("redfish"),
            AnyCodingKey(0),
            AnyCodingKey("bluefish"),
            AnyCodingKey("yellowfish"),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: newCodingPath, containerType: .Value)

        switch result {
        case let .success((objectId, codingKeyInstance)):
            XCTAssertEqual(codingKeyInstance.stringValue, "yellowfish")
            let pathToNewMap = try! doc.path(obj: objectId).stringPath()
            XCTAssertEqual(pathToNewMap, ".redfish.[0].bluefish")
        case let .failure(err):
            XCTFail("Failure looking up new path location: \(err)")
        }
    }

    func testCreateDeeperNewSchema_TooDeepFailure() throws {
        let newCodingPath: [AnyCodingKey] = [
            AnyCodingKey("redfish"),
            AnyCodingKey(5),
            AnyCodingKey("bluefish"),
            AnyCodingKey("yellowfish"),
        ]

        let result = AnyCodingKey.retrieveObjectId(document: doc, path: newCodingPath, containerType: .Value)
        switch result {
        case .success:
            XCTFail("Expected this to fail with index 5 in a new array")
        case let .failure(err):
            XCTAssertEqual(
                err.localizedDescription,
                "Index value 5 is too far beyond the length: 0 to append a new item."
            )
        }
    }
}
