import SwiftUI
import FinderKitCore
import AppKit

@main
struct FinderKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UpdateCoordinator.shared.scheduleBackgroundCheck()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let action = FinderKitDeepLink.parse(url) else { return }
        switch action {
        case .openObsidian(let folderPath):
            let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
            do {
                try ObsidianOpener.openFolder(at: folderURL)
            } catch {
                presentAlert(title: "Finder Kit", message: error.localizedDescription)
            }
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
