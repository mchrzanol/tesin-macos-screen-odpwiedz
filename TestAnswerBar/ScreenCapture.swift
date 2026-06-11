import Foundation
import CoreGraphics
import AppKit

enum ScreenCaptureError: LocalizedError {
    case captureFailed
    case pngConversionFailed

    var errorDescription: String? {
        switch self {
        case .captureFailed: return "Nie udało się przechwycić ekranu — dodaj tę aplikację (lub Terminal) w System Settings → Privacy & Security → Screen Recording"
        case .pngConversionFailed: return "Nie udało się skonwertować zrzutu do PNG"
        }
    }
}

enum ScreenCapture {
    /// Directory where screenshots are persisted.
    static var screenshotsDir: URL {
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Screenshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Captures the entire main display using CoreGraphics. Returns (imageData, savedFilePath).
    static func capture() throws -> (Data, URL) {
        guard let cgImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw ScreenCaptureError.captureFailed
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenCaptureError.pngConversionFailed
        }

        let timestamp = Self.timestamp()
        let fileURL = screenshotsDir.appendingPathComponent("screenshot_\(timestamp).png")
        try pngData.write(to: fileURL)

        return (pngData, fileURL)
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f.string(from: Date())
    }
}
