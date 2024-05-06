import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

struct Vote: Codable {
    var name: String
    var value: Int
    var data: Data = .init()
}

struct VoteCollection: Codable {
    var votes: [Vote] = []
}

extension Data {
    /// Returns cryptographically secure random data.
    ///
    /// - Parameter length: Length of the data in bytes.
    /// - Returns: Generated data of the specified length.
    static func random(length: Int) throws -> Data {
        Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
    }
}

final class SyncExplorationTests: XCTestCase {
    var encoder: AutomergeEncoder!
    var decoder: AutomergeDecoder!
    var doc: Document!

    override func setUp() async throws {
        doc = Document()
        encoder = AutomergeEncoder(doc: doc)
        decoder = AutomergeDecoder(doc: doc)
        try encoder.encode(VoteCollection())
        _ = doc.save()
    }

    func testSyncSize() throws {
        let docA = doc.fork()
        let docB = doc.fork()

        let docAEnc = AutomergeEncoder(doc: docA)
        let docBEnc = AutomergeEncoder(doc: docB)
        let docBDec = AutomergeDecoder(doc: docB)

        print("File size of docA at start is \(docA.save().count) bytes.")
        print("  docA has \(docA.getHistory().count) changes")
        print("File size of docB at start is \(docB.save().count) bytes.")
        print("  docB has \(docB.getHistory().count) changes")
        // docA sync to docB
        let syncStateA = SyncState()

        if let data = docA.generateSyncMessage(state: syncStateA) {
            print("Size of initial sync message is \(data.count) bytes.")
            let syncStateB = SyncState()
            let patchList = try docB.receiveSyncMessageWithPatches(state: syncStateB, message: data)
            print("patchlist has \(patchList.count) items")
            for p in patchList {
                print(" - \(p)")
            }
        }

        print("File size of docA at a->b is \(docA.save().count) bytes.")
        print("File size of docB at a->b is \(docB.save().count) bytes.")
        print("  docA has \(docA.getHistory().count) changes")
        print("  docB has \(docB.getHistory().count) changes")

        // Add data to each document
        var docAmodel = VoteCollection()
        try docAmodel.votes.append(Vote(name: "a", value: 0, data: Data.random(length: 8096)))
        try docAEnc.encode(docAmodel)
        _ = docA.save() // calling this is critical to incrementing # of changes...
        try docAmodel.votes.append(Vote(name: "b", value: 1, data: Data.random(length: 8096)))
        try docAEnc.encode(docAmodel)
        _ = docA.save()
        try docAmodel.votes.append(Vote(name: "c", value: -1, data: Data.random(length: 8096)))
        try docAEnc.encode(docAmodel)
        _ = docA.save()
        try docAmodel.votes.append(Vote(name: "d", value: 2, data: Data.random(length: 8096)))
        try docAEnc.encode(docAmodel)
        _ = docA.save()

        print("File size of docA at a->b, a+ is \(docA.save().count) bytes.")
        print("File size of docB at a->b, a+ is \(docB.save().count) bytes.")
        print("  docA has \(docA.getHistory().count) changes")
        print("  docB has \(docB.getHistory().count) changes")

        if let data = docA.generateSyncMessage(state: SyncState()) {
            print("Size of another new sync message, after data added, is \(data.count) bytes.")
            let syncStateB = SyncState()
            let patchList = try docB.receiveSyncMessageWithPatches(state: syncStateB, message: data)
            print("patchlist has \(patchList.count) items")
            for p in patchList {
                print(" - \(p)")
            }
        }

        print("File size of docA at a->b, a+, a->b is \(docA.save().count) bytes.")
        print("File size of docB at a->b, a+, a->b is \(docB.save().count) bytes.")
        print("  docA has \(docA.getHistory().count) changes")
        print("  docB has \(docB.getHistory().count) changes")

        var docBmodel = try docBDec.decode(VoteCollection.self)
        try docBmodel.votes.append(Vote(name: "å", value: 3, data: Data.random(length: 8096)))
        try docBEnc.encode(docBmodel)
        _ = docB.save()
        try docBmodel.votes.append(Vote(name: "∫", value: 2, data: Data.random(length: 8096)))
        try docBEnc.encode(docBmodel)
        _ = docB.save()
        try docBmodel.votes.append(Vote(name: "ç", value: 1, data: Data.random(length: 8096)))
        try docBEnc.encode(docBmodel)
        _ = docB.save()

        print("File size of docA at a->b, a+, a->b, b+ is \(docA.save().count) bytes.")
        print("File size of docB at a->b, a+, a->b, b+ is \(docB.save().count) bytes.")
        print("  docA has \(docA.getHistory().count) changes")
        print("  docB has \(docB.getHistory().count) changes")

        // docA sync to docB
        if let data = docA.generateSyncMessage(state: syncStateA) {
            print("Size of second sync message, after data is added, is \(data.count) bytes.")
        }

        let fullSyncStateA = SyncState()
        let fullSyncStateB = SyncState()

        print("FULL SYNC ROUND 1")
        if let data = docA.generateSyncMessage(state: fullSyncStateA) {
            print("Size of a new sync state message, after data added to both models, is \(data.count) bytes.")
            let patchList = try docB.receiveSyncMessageWithPatches(state: fullSyncStateB, message: data)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }
        if let returnMsg = docB.generateSyncMessage(state: fullSyncStateB) {
            print("DocB to DocA return sync message is \(returnMsg.count) bytes.")
            let patchList = try docA.receiveSyncMessageWithPatches(state: fullSyncStateA, message: returnMsg)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }

        print("FULL SYNC ROUND 2")
        if let data = docA.generateSyncMessage(state: fullSyncStateA) {
            print("Size of a new sync state message, after data added to both models, is \(data.count) bytes.")
            let patchList = try docB.receiveSyncMessageWithPatches(state: fullSyncStateB, message: data)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }
        if let returnMsg = docB.generateSyncMessage(state: fullSyncStateB) {
            print("DocB to DocA return sync message is \(returnMsg.count) bytes.")
            let patchList = try docA.receiveSyncMessageWithPatches(state: fullSyncStateA, message: returnMsg)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }

        print("FULL SYNC ROUND 3")
        if let data = docA.generateSyncMessage(state: fullSyncStateA) {
            print("Size of a new sync state message, after data added to both models, is \(data.count) bytes.")
            let patchList = try docB.receiveSyncMessageWithPatches(state: fullSyncStateB, message: data)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }
        if let returnMsg = docB.generateSyncMessage(state: fullSyncStateB) {
            print("DocB to DocA return sync message is \(returnMsg.count) bytes.")
            let patchList = try docA.receiveSyncMessageWithPatches(state: fullSyncStateA, message: returnMsg)
            print("patchlist has \(patchList.count) items")
//            for p in patchList {
//                print(" - \(p) to action \(p.action) at \(p.path)")
//            }
        }

        /*
         File size of docA at start is 121 bytes.
           docA has 1 changes
         File size of docB at start is 121 bytes.
           docB has 1 changes
         Size of initial sync message is 44 bytes.
         patchlist has 0 items
         File size of docA at a->b is 121 bytes.
         File size of docB at a->b is 121 bytes.
           docA has 1 changes
           docB has 1 changes
         File size of docA at a->b, a+ is 32713 bytes.
         File size of docB at a->b, a+ is 121 bytes.
           docA has 5 changes
           docB has 1 changes
         Size of another new sync message, after data added, is 49 bytes.
         patchlist has 0 items
         File size of docA at a->b, a+, a->b is 32713 bytes.
         File size of docB at a->b, a+, a->b is 121 bytes.
           docA has 5 changes
           docB has 1 changes
         File size of docA at a->b, a+, a->b, b+ is 32713 bytes.
         File size of docB at a->b, a+, a->b, b+ is 24587 bytes.
           docA has 5 changes
           docB has 4 changes
         Size of second sync message, after data is added, is 49 bytes.
         FULL SYNC ROUND 1
         Size of a new sync state message, after data added to both models, is 49 bytes.
         patchlist has 0 items
         DocB to DocA return sync message is 24845 bytes.
         patchlist has 10 items
         FULL SYNC ROUND 2
         Size of a new sync state message, after data added to both models, is 33129 bytes.
         patchlist has 13 items
         DocB to DocA return sync message is 135 bytes.
         patchlist has 0 items
         FULL SYNC ROUND 3
         */
    }
}
