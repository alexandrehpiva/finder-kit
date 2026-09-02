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
                presentAlert(title: "Finder Kit", message: error.localizedDescription, style: .warning)
            }
        case .copyPath(let folderPath):
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(folderPath, forType: .string)
            FinderKitLog.shared.info("host.copy_path.ok", source: .host, fields: ["path": folderPath])
        case .analyze(let folderPath):
            analyzeFolder(at: folderPath)
        }
    }

    private func analyzeFolder(at folderPath: String) {
        FinderKitLog.shared.info("host.analyze.start", source: .host, fields: ["path": folderPath])
        DispatchQueue.global(qos: .userInitiated).async {
            let folderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
            let result: Result<FolderStats, Error>
            do {
                let stats = try FolderAnalyzer.analyze(at: folderURL)
                result = .success(stats)
                FinderKitLog.shared.info(
                    "host.analyze.ok",
                    source: .host,
                    fields: [
                        "path": folderPath,
                        "bytes": String(stats.totalBytes),
                        "files": String(stats.fileCount),
                        "dirs": String(stats.directoryCount),
                    ]
                )
            } catch {
                result = .failure(error)
                FinderKitLog.shared.error(
                    "host.analyze.fail",
                    source: .host,
                    fields: ["path": folderPath, "error": error.localizedDescription]
                )
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self.presentAlert(
                        title: "Finder Kit — \(folderURL.lastPathComponent)",
                        message: """
                        Tamanho estimado: \(stats.formattedSize)
                        Arquivos: \(stats.fileCount)
                        Pastas: \(stats.directoryCount)

                        Contagem recursiva (arquivos visíveis no Finder).
                        """,
                        style: .informational
                    )
                case .failure(let error):
                    self.presentAlert(title: "Finder Kit", message: error.localizedDescription, style: .warning)
                }
            }
        }
    }

    private func presentAlert(title: String, message: String, style: NSAlert.Style = .warning) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
