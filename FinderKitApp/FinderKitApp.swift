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
        FinderKitLog.shared.installCrashReporting(source: .host)
        FinderKitLog.shared.info("host.launch", source: .host)
        NSApp.setActivationPolicy(.accessory)
        UpdateCoordinator.shared.scheduleBackgroundCheck()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        FinderKitLog.shared.info("host.deeplink", source: .host, fields: ["url": url.absoluteString])
        guard let action = FinderKitDeepLink.parse(url) else {
            FinderKitLog.shared.warn("host.deeplink_ignored", source: .host, fields: ["url": url.absoluteString])
            return
        }
        switch action {
        case .openObsidian(let folderPath):
            let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
            do {
                try ObsidianOpener.openFolder(at: folderURL)
                FinderKitLog.shared.info("host.obsidian.ok", source: .host, fields: ["path": folderPath])
            } catch {
                FinderKitLog.shared.error(
                    "host.obsidian.fail",
                    source: .host,
                    fields: ["path": folderPath, "error": error.localizedDescription]
                )
                presentAlert(title: "Finder Kit", message: error.localizedDescription)
            }
        case .copyPath(let folderPath):
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(folderPath, forType: .string)
            FinderKitLog.shared.info("host.copy_path.ok", source: .host, fields: ["path": folderPath])
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
