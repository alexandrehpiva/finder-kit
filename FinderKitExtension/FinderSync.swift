import Cocoa
import FinderKitCore
import FinderSync

final class FinderKitSync: FIFinderSync {
    override init() {
        super.init()
        FinderKitLog.shared.installCrashReporting(source: .appex)
        FinderKitLog.shared.info("appex.init", source: .appex)
        refreshMonitoredDirectories()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self,
            selector: #selector(refreshMonitoredDirectories),
            name: NSWorkspace.didMountNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(refreshMonitoredDirectories),
            name: NSWorkspace.didUnmountNotification,
            object: nil
        )
    }

    @objc private func refreshMonitoredDirectories() {
        let urls = FinderSyncRoots.directoryURLs()
        FIFinderSyncController.default().directoryURLs = urls
        FinderKitLog.shared.info(
            "appex.monitor_volumes",
            source: .appex,
            fields: ["count": String(urls.count)]
        )
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForItems:
            return menuForSelectedItems()
        case .contextualMenuForContainer:
            return menuForContainerBackground()
        default:
            return nil
        }
    }

    private func menuForSelectedItems() -> NSMenu? {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard urls.contains(where: { $0.hasDirectoryPath }) else { return nil }

        let menu = NSMenu(title: "")
        let analyze = menu.addItem(
            withTitle: "Finder Kit — Calcular tamanho…",
            action: #selector(analyzeSelectedFolder(_:)),
            keyEquivalent: ""
        )
        analyze.target = self

        let obsidian = menu.addItem(
            withTitle: "Abrir no Obsidian",
            action: #selector(openSelectedFoldersInObsidian(_:)),
            keyEquivalent: ""
        )
        obsidian.target = self

        let copyPath = menu.addItem(
            withTitle: "Copiar caminho",
            action: #selector(copySelectedFolderPaths(_:)),
            keyEquivalent: ""
        )
        copyPath.target = self
        return menu
    }

    private func menuForContainerBackground() -> NSMenu? {
        guard FIFinderSyncController.default().targetedURL() != nil else { return nil }

        let menu = NSMenu(title: "")
        let obsidian = menu.addItem(
            withTitle: "Abrir no Obsidian",
            action: #selector(openTargetedFolderInObsidian(_:)),
            keyEquivalent: ""
        )
        obsidian.target = self

        let copyPath = menu.addItem(
            withTitle: "Copiar caminho",
            action: #selector(copyTargetedFolderPath(_:)),
            keyEquivalent: ""
        )
        copyPath.target = self
        return menu
    }

    @objc private func analyzeSelectedFolder(_ sender: NSMenuItem) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard let folderURL = urls.first(where: { $0.hasDirectoryPath }) else {
            FinderKitLog.shared.warn("analyze.no_selection", source: .appex)
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }

        FinderKitLog.shared.info(
            "analyze.start",
            source: .appex,
            fields: ["path": folderURL.path]
        )

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result: Result<FolderStats, Error>
            do {
                let stats = try SecurityScopedAccess.withAccess(to: folderURL) {
                    try FolderAnalyzer.analyze(at: folderURL)
                }
                result = .success(stats)
                FinderKitLog.shared.info(
                    "analyze.ok",
                    source: .appex,
                    fields: [
                        "path": folderURL.path,
                        "bytes": String(stats.totalBytes),
                        "files": String(stats.fileCount),
                        "dirs": String(stats.directoryCount),
                    ]
                )
            } catch {
                result = .failure(error)
                FinderKitLog.shared.error(
                    "analyze.fail",
                    source: .appex,
                    fields: ["path": folderURL.path, "error": error.localizedDescription]
                )
            }

            DispatchQueue.main.async {
                FinderKitLog.shared.info("analyze.present_ui", source: .appex, fields: ["path": folderURL.path])
                self?.presentResult(result, folderName: folderURL.lastPathComponent)
            }
        }
    }

    @objc private func openSelectedFoldersInObsidian(_ sender: NSMenuItem) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        let folders = urls.filter(\.hasDirectoryPath)
        guard !folders.isEmpty else {
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }
        requestHostOpenObsidian(folders: folders)
    }

    @objc private func openTargetedFolderInObsidian(_ sender: NSMenuItem) {
        guard let folderURL = FIFinderSyncController.default().targetedURL() else {
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }
        requestHostOpenObsidian(folders: [folderURL])
    }

    @objc private func copySelectedFolderPaths(_ sender: NSMenuItem) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        let folders = urls.filter(\.hasDirectoryPath)
        guard !folders.isEmpty else {
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }
        requestHostCopyPath(folders: folders)
    }

    @objc private func copyTargetedFolderPath(_ sender: NSMenuItem) {
        guard let folderURL = FIFinderSyncController.default().targetedURL() else {
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }
        requestHostCopyPath(folders: [folderURL])
    }

    /// A extensão é sandboxed; o host (sem sandbox) executa `open -a Obsidian`.
    private func requestHostOpenObsidian(folders: [URL]) {
        for folder in folders {
        FinderKitLog.shared.info(
            "obsidian.request",
            source: .appex,
            fields: ["path": folder.path]
        )
            let deepLink = FinderKitDeepLink.makeOpenObsidianURL(folderURL: folder)
            let opened = NSWorkspace.shared.open(deepLink)
            if !opened {
                FinderKitLog.shared.error("obsidian.host_open_failed", source: .appex, fields: ["path": folder.path])
                presentAlert(
                    title: "Finder Kit",
                    message: """
                    Não foi possível acionar o FinderKit.app para abrir o Obsidian.
                    Confirme que o app está em /Applications ou ~/Applications e abra-o uma vez.
                    """
                )
                return
            }
        }
    }

    /// Clipboard geral: host copia o path POSIX (sandbox da extensão é instável no pasteboard).
    private func requestHostCopyPath(folders: [URL]) {
        let payload: String
        do {
            payload = try FolderPathClipboard.posixPaths(of: folders)
        } catch {
            presentAlert(title: "Finder Kit", message: error.localizedDescription)
            return
        }
        let deepLink = FinderKitDeepLink.makeCopyPathURL(folderPath: payload)
        FinderKitLog.shared.info(
            "copy_path.request",
            source: .appex,
            fields: ["path": payload]
        )
        let opened = NSWorkspace.shared.open(deepLink)
        if !opened {
            FinderKitLog.shared.error("copy_path.host_open_failed", source: .appex)
            presentAlert(
                title: "Finder Kit",
                message: """
                Não foi possível copiar o caminho via FinderKit.app.
                Confirme que o app está em /Applications ou ~/Applications e abra-o uma vez.
                """
            )
        }
    }

    private func presentResult(_ result: Result<FolderStats, Error>, folderName: String) {
        switch result {
        case .success(let stats):
            presentAlert(
                title: "Finder Kit — \(folderName)",
                message: """
                Tamanho estimado: \(stats.formattedSize)
                Arquivos: \(stats.fileCount)
                Pastas: \(stats.directoryCount)

                Contagem recursiva (arquivos visíveis no Finder).
                """
            )
        case .failure(let error):
            presentAlert(title: "Finder Kit", message: error.localizedDescription)
        }
    }

    private func presentAlert(title: String, message: String) {
        FinderKitLog.shared.info(
            "ui.alert",
            source: .appex,
            fields: ["title": title, "message": String(message.prefix(200))]
        )
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
