import Foundation

enum APIConfig {
    /// OpenRouter API key.
    ///
    /// Priority:
    /// 1. Environment variable OPENROUTER_API_KEY (e.g. set in Xcode scheme)
    /// 2. Value from .env file next to the binary / in project root
    static var openRouterKey: String {
        if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        return loadFromDotEnv(key: "OPENROUTER_API_KEY") ?? ""
    }

    /// Reads a KEY=VALUE from .env file.
    /// Searches: working directory, then binary's parent directory.
    private static func loadFromDotEnv(key: String) -> String? {
        let candidates = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".env"),
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(".env")
        ]

        for url in candidates {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for line in contents.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("#"), trimmed.contains("=") else { continue }
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                if parts.count == 2, String(parts[0]).trimmingCharacters(in: .whitespaces) == key {
                    return String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}
