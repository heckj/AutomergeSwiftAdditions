import ArgumentParser
import Automerge
import Foundation
import OSLog
import PotentCBOR
import PotentCodables

/// A CBOR encoded wrapper around a serialized Automerge document.
///
/// The `id` is a unique identifier that provides a "new document" identifier for the purpose of comparing two documents
/// to determine if they were branched from the same root document.
struct WrappedAutomergeDocument: Codable {
    let id: UUID
    let data: Data
    static let fileEncoder = CBOREncoder()
    static let fileDecoder = CBORDecoder()
}

func tryDecodingWrappedDoc(from data: Data) -> Document? {
    do {
        Logger.document.debug("Attempting to decode \(data.count, privacy: .public) bytes as a CBOR encoded Automerge doc")
        print("Attempting to decode \(data.count) bytes as a CBOR encoded Automerge doc")
        let wrappedDoc = try WrappedAutomergeDocument.fileDecoder.decode(WrappedAutomergeDocument.self, from: data)
        return tryDecodingRawAutomergeDoc(from: wrappedDoc.data)
    } catch {
        Logger.document.warning("\(error)")
        print(error)
        return nil
    }
}

func tryDecodingRawAutomergeDoc(from data: Data) -> Document? {
    do {
        Logger.document.debug("Attempting to decode \(data.count, privacy: .public) bytes as a raw Automerge doc")
        print("Attempting to decode \(data.count) bytes as a raw Automerge doc")
        let doc = try Document(data)
        return doc
    } catch {
        Logger.document.error("\(error)")
        print(error)
        return nil
    }
}

extension AMInspector {
    struct Info: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "info",
            abstract: "Inspects and prints general metrics about Automerge files."
        )

        @OptionGroup var options: AMInspector.Options

        @Flag(
            name: [.customShort("v"), .long],
            help: "List the changeset hashes."
        )
        var verbose = false

        mutating func run() throws {
            let data: Data
            let doc: Document
            do {
                data = try Data(contentsOf: URL(fileURLWithPath: options.inputFile))
            } catch {
                print("Unable to open file at \(options.inputFile).")
                AMInspector.exit(withError: error)
            }

            if let docFromWrap = tryDecodingWrappedDoc(from: data) {
                doc = docFromWrap
            } else if let rawDoc = tryDecodingRawAutomergeDoc(from: data) {
                doc = rawDoc
            } else {
                print("\(options.inputFile) is not an Automerge document.")
                AMInspector.exit()
            }

            let changesets = doc.heads()
            print("Filename: \(options.inputFile)")
            print("- Size: \(data.count) bytes")
            print("- ActorId: \(doc.actor)")
            print("- ChangeSets: \(doc.heads().count)")
            if verbose {
                for cs in changesets {
                    print("  - \(cs)")
                }
            }
        }
    }
}
