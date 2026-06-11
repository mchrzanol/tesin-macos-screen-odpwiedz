import SwiftUI

@main
struct TestAnswerBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — everything lives in the menu bar via AppDelegate
        Settings { EmptyView() }
    }
}
