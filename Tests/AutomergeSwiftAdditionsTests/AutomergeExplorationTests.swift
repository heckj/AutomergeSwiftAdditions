//
//  AutomergeExplorationTests.swift
//  AMTravelNotesTests
//
//  Created by Joseph Heck on 3/23/23.
//

import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

final class AutomergeExplorationTests: XCTestCase {

    func testReadBeyondIndex() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        // let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)

        // intentionally beyond end of list
        XCTAssertNoThrow(try doc.get(obj: list, index: 32))
        let experiment: Value? = try doc.get(obj: list, index: 32)
        XCTAssertNil(experiment)
        // print(String(describing: experiment))
    }

    func testInsertBeyondIndex() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)

        try doc.insert(obj: list, index: 0, value: .Int(0))
        try doc.insert(obj: list, index: 1, value: .Int(1))
        try doc.insert(obj: list, index: 2, value: .Int(2))

        // If you attempt to insert beyond the index/length of the existing array, you'll
        // get a DocError - with an inner error describing: index out of bounds
        XCTAssertEqual(doc.length(obj: list), 3)

        XCTAssertEqual(Value.Scalar(.Int(0)), try doc.get(obj: list, index: 0))
        XCTAssertEqual(Value.Scalar(.Int(1)), try doc.get(obj: list, index: 1))
        XCTAssertEqual(Value.Scalar(.Int(2)), try doc.get(obj: list, index: 2))
        XCTAssertNil(try doc.get(obj: list, index: 3))
        XCTAssertNil(try doc.get(obj: list, index: 4))
    }

    func testSyncStateUpdating() throws {
        let doc1 = Document()
        let syncState1 = SyncState()

        let doc2 = Document()
        let syncState2 = SyncState()

        try! doc1.put(obj: ObjId.ROOT, key: "key1", value: .String("value1"))
        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))

        XCTAssertNil(syncState1.theirHeads)
        let syncDataMsg = try XCTUnwrap(doc1.generateSyncMessage(state: syncState1))
        print("sync msg size: \(syncDataMsg.count) bytes")
        // syncState1 isn't updated by generating a sync message
        //   .. so at this point syncState1 is effectively "empty" and doesn't contain a list of
        //      any change hashes
        // XCTAssertNotNil(syncState1.theirHeads)
        // print("size of changes in syncState1: \(syncState1.theirHeads?.count)")

        // And we generally want to keep iterating sync messages UNTIL the syncDataMsg result
        // is nil, which indicates that nothing further needs to be synced.

        XCTAssertNil(syncState2.theirHeads)
        try doc2.receiveSyncMessage(state: syncState2, message: syncDataMsg)
        XCTAssertNotNil(syncState2.theirHeads) // it IS updated when you invoke receiveSyncMessages(...)
        print("size of changes in syncState2: \(syncState2.theirHeads?.count ?? -1)")
        for change in syncState2.theirHeads! {
            print(" -> ChangeHash: \(change)")
        }
        // XCTAssertEqual(syncState1.theirHeads, syncState2.theirHeads)
    }
}
