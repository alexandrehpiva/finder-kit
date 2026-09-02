import Cocoa
import FinderKitCore
import FinderSync

final class FinderKitSync: FIFinderSync {
    override init() {
        super.init()
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
        FIFinderSyncController.default().directoryURLs = FinderSyncRoots.directoryURLs()
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
        return menu
    }

    @objc private func analyzeSelectedFolder(_ sender: NSMenuItem) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard let folderURL = urls.first(where: { $0.hasDirectoryPath }) else {
            presentAlert(title: "Finder Kit", message: FinderKitError.noSelection.localizedDescription)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result: Result<FolderStats, Error>
            do {
                let stats = try SecurityScopedAccess.withAccess(to: folderURL) {
                    try FolderAnalyzer.analyze(at: folderURL)
                }
                result = .success(stats)
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
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

    /// A extensão é sandboxed; o host (sem sandbox) executa `open -a Obsidian`.
    private func requestHostOpenObsidian(folders: [URL]) {
        for folder in folders {
            let deepLink = FinderKitDeepLink.makeOpenObsidianURL(folderURL: folder)
            let opened = NSWorkspace.shared.open(deepLink)
            if !opened {
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
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
