import Automerge
@testable import AutomergeSwiftAdditions
import XCTest

struct Vote: Codable {
    var name: String
    var value: Int
}

struct VoteCollection: Codable {
    var votes: [Vote] = []
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
    }
    
    func testSyncSize() throws {
        let docA = doc.fork()
        let docB = doc.fork()
        
        let docAEnc = AutomergeEncoder(doc: docA)
        let docBEnc = AutomergeEncoder(doc: docB)
        let docBDec = AutomergeDecoder(doc: docB)
        
        print("File size of docA at start is \(docA.save().count) bytes.")
        print("  docA has \(docA.changes().count) changes")
        print("File size of docB at start is \(docB.save().count) bytes.")
        print("  docB has \(docB.changes().count) changes")
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
        print("  docA has \(docA.changes().count) changes")
        print("  docB has \(docB.changes().count) changes")

        // Add data to each document
        var docAmodel = VoteCollection()
        docAmodel.votes.append(Vote(name: "a", value: 0))
        try docAEnc.encode(docAmodel)
        docA.save() // calling this is critical to incrementing # of changes...
        docAmodel.votes.append(Vote(name: "b", value: 1))
        try docAEnc.encode(docAmodel)
        docA.save()
        docAmodel.votes.append(Vote(name: "c", value: -1))
        try docAEnc.encode(docAmodel)
        docA.save()
        docAmodel.votes.append(Vote(name: "d", value: 2))
        try docAEnc.encode(docAmodel)
        docA.save()
        
        print("File size of docA at a->b, a+ is \(docA.save().count) bytes.")
        print("File size of docB at a->b, a+ is \(docB.save().count) bytes.")
        print("  docA has \(docA.changes().count) changes")
        print("  docB has \(docB.changes().count) changes")

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
        print("  docA has \(docA.changes().count) changes")
        print("  docB has \(docB.changes().count) changes")

        var docBmodel = try docBDec.decode(VoteCollection.self)
        docBmodel.votes.append(Vote(name: "å", value: 3))
        try docBEnc.encode(docBmodel)
        docB.save()
        docBmodel.votes.append(Vote(name: "∫", value: 2))
        try docBEnc.encode(docBmodel)
        docB.save()
        docBmodel.votes.append(Vote(name: "ç", value: 1))
        try docBEnc.encode(docBmodel)
        docB.save()
        
        print("File size of docA at a->b, a+, a->b, b+ is \(docA.save().count) bytes.")
        print("File size of docB at a->b, a+, a->b, b+ is \(docB.save().count) bytes.")
        print("  docA has \(docA.changes().count) changes")
        print("  docB has \(docB.changes().count) changes")

        // docA sync to docB
        if let data = docA.generateSyncMessage(state: syncStateA) {
            print("Size of second sync message, after data is added, is \(data.count) bytes.")
        }
    
        if let data = docA.generateSyncMessage(state: SyncState()) {
            print("Size of a new sync state message, after data added to both models, is \(data.count) bytes.")
            let syncStateB = SyncState()
            let patchList = try docB.receiveSyncMessageWithPatches(state: syncStateB, message: data)
            print("patchlist has \(patchList.count) items")
            for p in patchList {
                print(" - \(p)")
            }

        }
        /*
         File size of docA at start is 121 bytes.
         Size of initial sync message is 44 bytes.
         Size of second sync message is 45 bytes.
         Size of a new syncstate message is 45 bytes.
         */
    }

}
