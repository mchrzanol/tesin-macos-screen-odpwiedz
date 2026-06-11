import Foundation

enum HistoryLogger {
    private static var logFile: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("answers.log")
    }

    /// Appends one line: timestamp | screenshot filename | answer
    static func log(screenshotURL: URL, answer: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = screenshotURL.lastPathComponent
        let line = "\(timestamp) | \(filename) | \(answer)\n"

        let url = logFile
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                handle.closeFile()
            }
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
