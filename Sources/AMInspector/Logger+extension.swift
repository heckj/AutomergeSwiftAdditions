import Foundation
import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = "com.github.heckj.AMInspector"

    /// Logs the Document interactions, such as saving and loading.
    static let document = Logger(subsystem: subsystem, category: "Document")
}
