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

        let _ = try! doc.put(obj: ObjId.ROOT, key: "name", value: .String("joe"))

        let description = try! doc.putObject(obj: ObjId.ROOT, key: "description", ty: .Text)
        setupCache["description"] = description

        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list

        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        setupCache["nestedMap"] = nestedMap

        try! doc.put(obj: nestedMap, key: "image", value: .Bytes(Data()))
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        setupCache["deeplyNestedText"] = deeplyNestedText
    }

    func testSetupDocPath() throws {
        let pathToText = try! doc.path(obj: setupCache["deeplyNestedText"]!).stringPath()
        XCTAssertEqual(setupCache.count, 4)
        XCTAssertEqual(pathToText, ".list.[0].notes")
    }

    func testPathAtRoot() throws {
        let doc = Document()
        let path = try! doc.path(obj: ObjId.ROOT)
        XCTAssertEqual(path, [])
    }

    func testOverrideStrategy() throws {
        let result = doc.retrieveObjectId(path: [AnyCodingKey("list")], containerType: .Key, strategy: .override)
        switch result {
        case let .success(success):
            XCTFail("Expected override not implemented error, received: \(success)")
        case .failure:
            break
        }
    }

    func testInvalidIndexLookup() throws {
        let result = doc.retrieveObjectId(path: [], containerType: .Index, strategy: .readonly)
        switch result {
        case let .success(success):
            XCTFail("Expected invalid lookup error, received: \(success)")
        case .failure:
            break
        }
    }

    func testInvalidValueLookup() throws {
        let result = doc.retrieveObjectId(path: [], containerType: .Value, strategy: .override)
        switch result {
        case let .success(success):
            XCTFail("Expected invalid lookup error, received: \(success)")
        case .failure:
            break
        }
    }

    func testLookupThroughText() throws {
        let result = doc.retrieveObjectId(
            path: [AnyCodingKey("description"), AnyCodingKey("list")],
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success(success):
            XCTFail("Expected invalid lookup error, received: \(success)")
        case .failure:
            break
        }
    }

    func testLookupThroughScalar() throws {
        let result = doc.retrieveObjectId(
            path: [AnyCodingKey("joe"), AnyCodingKey("age")],
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success(success):
            XCTFail("Expected invalid lookup error, received: \(success)")
        case .failure:
            break
        }
    }

    func testLookupBeyondBounds() throws {
        let result = doc.retrieveObjectId(
            path: [AnyCodingKey("list"), AnyCodingKey(2), AnyCodingKey("name")],
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success(success):
            XCTFail("Expected invalid lookup error, received: \(success)")
        case .failure:
            break
        }
    }

    func testRetrieveLeafValue() throws {
        let fullCodingPath: [AnyCodingKey] = [
            AnyCodingKey("list"),
            AnyCodingKey(0),
            AnyCodingKey("notes"),
        ]

        let result = doc.retrieveObjectId(
            path: fullCodingPath,
            containerType: .Value,
            strategy: .createWhenNeeded
        )

        switch result {
        case let .success(objectId):
            XCTAssertEqual(objectId, setupCache["nestedMap"])
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

        let result = doc.retrieveObjectId(
            path: newCodingPath,
            containerType: .Key,
            strategy: .createWhenNeeded
        )

        switch result {
        case let .success(objectId):
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

        let result = doc.retrieveObjectId(
            path: newCodingPath,
            containerType: .Key,
            strategy: .createWhenNeeded
        )

        switch result {
        case let .success(objectId):
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

        let result = doc.retrieveObjectId(
            path: newCodingPath,
            containerType: .Index,
            strategy: .createWhenNeeded
        )

        switch result {
        case let .success(objectId):
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

        let result = doc.retrieveObjectId(
            path: newCodingPath,
            containerType: .Value,
            strategy: .createWhenNeeded
        )

        switch result {
        case let .success(objectId):
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

        let result = doc.retrieveObjectId(
            path: newCodingPath,
            containerType: .Value,
            strategy: .createWhenNeeded
        )
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
