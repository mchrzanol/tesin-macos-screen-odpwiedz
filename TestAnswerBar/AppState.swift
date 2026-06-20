import Foundation
import SwiftUI

enum AppStatus: Equatable {
    case idle
    case processing
    case result(String)
    case error(String)
}

@MainActor
final class AppState: ObservableObject {
    @Published var status: AppStatus = .idle

    private let networkManager = NetworkManager()
    private var resetTask: Task<Void, Never>?

    func captureAndAnalyze() async {
        guard status != .processing else { return }

        resetTask?.cancel()
        status = .processing
        print("[LOG] Cmd+Shift+1 wykryty — robię zrzut ekranu...")

        do {
            let (imageData, screenshotURL) = try ScreenCapture.capture()
            print("[LOG] Screenshot zapisany: \(screenshotURL.lastPathComponent) (\(imageData.count / 1024) KB)")

            print("[LOG] Wysyłam do OpenRouter API...")
            let answer = try await networkManager.analyzeImage(imageData: imageData)

            HistoryLogger.log(screenshotURL: screenshotURL, answer: answer)

            status = .result(answer)
            print("[LOG] Odpowiedź: \(answer)")

            resetTask = Task {
                try? await Task.sleep(for: .seconds(15))
                if !Task.isCancelled {
                    self.status = .idle
                    print("[LOG] Reset do stanu spoczynku")
                }
            }
        } catch {
            status = .error(error.localizedDescription)
            print("[ERROR] \(error.localizedDescription)")
            resetTask = Task {
                try? await Task.sleep(for: .seconds(10))
                if !Task.isCancelled {
                    self.status = .idle
                }
            }
        }
    }

    /// Clears any displayed answer/error and returns to the idle (waiting) icon.
    func dismiss() {
        resetTask?.cancel()
        status = .idle
        print("[LOG] Odpowiedź ukryta — powrót do stanu spoczynku")
    }
}
