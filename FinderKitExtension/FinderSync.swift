import Cocoa
import FinderKitCore
import FinderSync

final class FinderKitSync: FIFinderSync {
    override init() {
        super.init()
        // Monitora volumes para o Finder exibir o menu em pastas do usuário.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }

        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard urls.contains(where: { $0.hasDirectoryPath }) else { return nil }

        let menu = NSMenu(title: "")
        let item = menu.addItem(
            withTitle: "Finder Kit — Calcular tamanho…",
            action: #selector(analyzeSelectedFolder(_:)),
            keyEquivalent: ""
        )
        item.target = self
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
                result = .success(try FolderAnalyzer.analyze(at: folderURL))
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                self?.presentResult(result, folderName: folderURL.lastPathComponent)
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
