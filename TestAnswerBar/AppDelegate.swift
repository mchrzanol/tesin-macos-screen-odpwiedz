import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var globalMonitor: Any?
    private var statusItem: NSStatusItem!
    private var cancellable: AnyCancellable?
    private var animationTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("==========================================")
        print("  TestAnswerBar uruchomiony!")
        print("  Skrót: Cmd+Shift+1 = zrzut + analiza")
        print("  Ctrl+C = zamknij")
        print("==========================================")

        setupStatusItem()
        setupGlobalHotkey()
        observeState()
    }

    // MARK: - Status Item (menu bar icon)

    private func setupStatusItem() {
        // .variableLength lets the item grow for text like "Odp: 1, 3"
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // autosaveName makes macOS remember position after Cmd+drag
        statusItem.autosaveName = "TestAnswerBar"
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "TestAnswerBar")
            button.imagePosition = .imageLeading
        }

        // Build the dropdown menu
        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "Gotowy (Cmd+Shift+1)", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 100
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        let captureItem = NSMenuItem(title: "Zrób zrzut teraz", action: #selector(captureAction), keyEquivalent: "")
        captureItem.target = self
        menu.addItem(captureItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Zakończ", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Observe state changes → update icon

    private func observeState() {
        cancellable = appState.$status.receive(on: RunLoop.main).sink { [weak self] status in
            self?.updateStatusItem(for: status)
        }
    }

    private func updateStatusItem(for status: AppStatus) {
        guard let button = statusItem.button else { return }

        stopAnimation()

        switch status {
        case .idle:
            button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: nil)
            button.title = ""
            updateMenuItem("Gotowy (Cmd+Shift+1)")

        case .processing:
            button.title = ""
            startLoadingAnimation(button: button)
            updateMenuItem("Analizuję zrzut ekranu...")

        case .result(let answer):
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            button.title = " \(answer)"
            updateMenuItem("Odpowiedź: \(answer)")

        case .error(let msg):
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
            button.title = ""
            updateMenuItem("Błąd: \(msg)")
        }
    }

    private func updateMenuItem(_ text: String) {
        if let item = statusItem.menu?.item(withTag: 100) {
            item.title = text
        }
    }

    // MARK: - Spinning animation (cycles SF Symbols)

    private let spinFrames = [
        "circle.dotted",
        "circle.bottomhalf.filled",
        "circle.lefthalf.filled",
        "circle.tophalf.filled",
        "circle.righthalf.filled",
    ]
    private var spinIndex = 0

    private func startLoadingAnimation(button: NSStatusBarButton) {
        spinIndex = 0
        button.image = NSImage(systemSymbolName: spinFrames[0], accessibilityDescription: nil)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.spinIndex = (self.spinIndex + 1) % self.spinFrames.count
                button.image = NSImage(systemSymbolName: self.spinFrames[self.spinIndex], accessibilityDescription: nil)
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 18 {
                Task { @MainActor in
                    await self.appState.captureAndAnalyze()
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func captureAction() {
        Task { await appState.captureAndAnalyze() }
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopAnimation()
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
