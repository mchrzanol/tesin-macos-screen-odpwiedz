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
        print("  Skrót: Fn+Shift = zrzut + analiza")
        print("  Skrót: Fn+Caps = ukryj odpowiedź")
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

        let statusMenuItem = NSMenuItem(title: "Gotowy (Fn+Shift)", action: nil, keyEquivalent: "")
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
            updateMenuItem("Gotowy (Fn+Shift)")

        case .processing:
            button.title = ""
            startLoadingAnimation(button: button)
            updateMenuItem("Analizuję zrzut ekranu...")

        case .result(let answer):
            button.image = nil
            button.title = answer
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

    // MARK: - Loading animation (subtle opacity pulse)

    private var pulseBright = false

    private func startLoadingAnimation(button: NSStatusBarButton) {
        // Keep the regular brain icon, just breathe its opacity so it's
        // noticeable without being distracting.
        button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: nil)
        pulseBright = false
        button.alphaValue = 0.3
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.pulseBright.toggle()
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.7
                    button.animator().alphaValue = self.pulseBright ? 1.0 : 0.3
                }
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        statusItem?.button?.alphaValue = 1.0
    }

    // MARK: - Global Hotkey

    // Tracks whether Fn+Shift were both held on the previous event, so we
    // only fire once when the combo becomes active (not on every release).
    private var hotkeyActive = false

    // Same idea for the Fn+Caps "dismiss" combo, tracked independently.
    private var dismissActive = false

    private func setupGlobalHotkey() {
        // Fn+Shift are pure modifiers, so listen for .flagsChanged rather than .keyDown.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }

            let comboHeld = event.modifierFlags.contains([.function, .shift])
            if comboHeld && !self.hotkeyActive {
                self.hotkeyActive = true
                Task { @MainActor in
                    await self.appState.captureAndAnalyze()
                }
            } else if !comboHeld {
                self.hotkeyActive = false
            }

            // Fn+Caps hides the current answer and returns to the waiting icon.
            let dismissHeld = event.modifierFlags.contains([.function, .capsLock])
            if dismissHeld && !self.dismissActive {
                self.dismissActive = true
                Task { @MainActor in
                    self.appState.dismiss()
                }
            } else if !dismissHeld {
                self.dismissActive = false
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
