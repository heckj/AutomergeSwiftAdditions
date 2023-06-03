//
//  AutomergeExplorationTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 3/23/23.
//

import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

final class Document_PathTests: XCTestCase {
    func testPath() throws {
        XCTAssertNotNil(PathCache.objId)
        XCTAssertEqual(PathCache.objId.count, 0)

        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)

        XCTAssertEqual(PathCache.objId.count, 0)

        let result = try XCTUnwrap(doc.lookupPath(path: ""))
        XCTAssertEqual(result, ObjId.ROOT)

        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: "")))
        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: ".")))
        XCTAssertNil(try doc.lookupPath(path: "a"))
        XCTAssertNil(try doc.lookupPath(path: "a."))
        XCTAssertEqual(try doc.lookupPath(path: "list"), list)
        XCTAssertEqual(try doc.lookupPath(path: ".list"), list)
        XCTAssertNil(try doc.lookupPath(path: "list.[1]"))

        XCTAssertThrowsError(try doc.lookupPath(path: ".list.[5]"), "Index Out of Bounds should throw an error")
        // The top level object isn't a list - so an index lookup should fail with an error
        XCTAssertThrowsError(try doc.lookupPath(path: "[1].a"))

        // XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: "1.a")))
        // threw error "DocError(inner: AutomergeUniffi.DocError.WrongObjectType(message: "WrongObjectType"))"
        XCTAssertEqual(try doc.lookupPath(path: "list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath(path: ".list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath(path: "list.[0].notes"), deeplyNestedText)
        XCTAssertEqual(try doc.lookupPath(path: ".list.[0].notes"), deeplyNestedText)
        print("Cache: \(PathCache.objId)")
        /*
         Cache: [
         ".list.[0]": (ObjId(1010d753481b2afb40a5b353e66bc0df63120002, Automerge.ObjType.Map),
         ".list": (ObjId(1010d753481b2afb40a5b353e66bc0df63120001, Automerge.ObjType.List),
         ".list.[0].notes": (ObjId(1010d753481b2afb40a5b353e66bc0df63120003, Automerge.ObjType.Text)
         ]
         */

        // verifying cache lookups

        XCTAssertEqual(PathCache.objId.count, 3)
        XCTAssertNotNil(PathCache.objId[".list"])
        XCTAssertNil(PathCache.objId["list"])
        XCTAssertNil(PathCache.objId["a"])
    }

    func testPathLookup2() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)

        let result = try XCTUnwrap(doc.lookupPath2(path: ""))
        XCTAssertEqual(result, ObjId.ROOT)

        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath2(path: "")))
        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath2(path: ".")))
        XCTAssertNil(try doc.lookupPath2(path: "a"))
        XCTAssertNil(try doc.lookupPath2(path: "a."))
        XCTAssertEqual(try doc.lookupPath2(path: "list"), list)
        XCTAssertEqual(try doc.lookupPath2(path: ".list"), list)
        XCTAssertNil(try doc.lookupPath2(path: "list.[1]"))

        // XCTAssertThrowsError(try doc.lookupPath2(path: ".list.[5]"), "Index Out of Bounds should throw an error")
        XCTAssertNil(try doc.lookupPath2(path: ".list.[5]"))

        // The top level object isn't a list - so an index lookup should fail with an error
        // XCTAssertThrowsError(try doc.lookupPath2(path: "[1].a"))
        XCTAssertNil(try doc.lookupPath2(path: "[1].a"))

        // XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: "1.a")))
        // threw error "DocError(inner: AutomergeUniffi.DocError.WrongObjectType(message: "WrongObjectType"))"
        XCTAssertEqual(try doc.lookupPath2(path: "list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath2(path: ".list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath2(path: "list.[0].notes"), deeplyNestedText)
        XCTAssertEqual(try doc.lookupPath2(path: ".list.[0].notes"), deeplyNestedText)
    }
}
