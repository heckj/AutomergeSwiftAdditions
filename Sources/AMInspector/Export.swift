import ArgumentParser
import Automerge
import Foundation
import OSLog

extension AMInspector {
    struct Export: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "export",
            abstract: "Exports the internal Automerge document from a wrapped version (aka MeetingNotes)."
        )
        
        @OptionGroup var options: AMInspector.Options
        
        mutating func run() throws {
            let data: Data
            let doc: Document
            do {
                data = try Data(contentsOf: URL(fileURLWithPath: options.inputFile))
            } catch {
                print("Unable to open file at \(options.inputFile).")
                AMInspector.exit(withError: error)
            }
            
            do {
                Logger.document
                    .debug("Attempting to decode \(data.count, privacy: .public) bytes as a CBOR encoded Automerge doc")
                print("Attempting to decode \(data.count) bytes as a CBOR encoded Automerge doc")
                let wrappedDoc = try DocumentIdWrappedAutomergeDocument.fileDecoder.decode(DocumentIdWrappedAutomergeDocument.self, from: data)
                let location = URL.init(filePath: "./rawautomergefile")
                try wrappedDoc.data.write(to: location, options: .atomic)
            } catch {
                Logger.document.error("\(error)")
                print(error)                
            }
        }
        
    }
}
