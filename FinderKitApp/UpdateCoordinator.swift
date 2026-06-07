import AppKit
import FinderKitCore
import Foundation

@MainActor
final class UpdateCoordinator {
  static let shared = UpdateCoordinator()

  private var checkTask: Task<Void, Never>?

  func scheduleBackgroundCheck(after seconds: TimeInterval = 3) {
    checkTask?.cancel()
    checkTask = Task {
      try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
      guard !Task.isCancelled else { return }
      await checkForUpdates(interactive: false)
    }
  }

  func checkForUpdates(interactive: Bool) async {
    let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    do {
      let release = try await ReleaseChecker.fetchLatestRelease()
      guard ReleaseChecker.isNewer(latest: release.version, than: current) else {
        if interactive {
          presentInfo(title: "Finder Kit", message: "Você já está na versão mais recente (\(current)).")
        }
        return
      }
      promptToUpgrade(latest: release.version)
    } catch {
      if interactive {
        presentInfo(title: "Finder Kit", message: error.localizedDescription)
      }
    }
  }

  private func promptToUpgrade(latest: String) {
    let alert = NSAlert()
    alert.messageText = "Atualização disponível"
    alert.informativeText = "Finder Kit \(latest) está disponível no GitHub. Atualizar agora?"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Atualizar")
    alert.addButton(withTitle: "Depois")

    guard alert.runModal() == .alertFirstButtonReturn else { return }
    runUpgradeScript()
  }

  func runUpgradeScript() {
    let candidates = [
      Bundle.main.url(forResource: "upgrade", withExtension: "sh"),
      FinderKitPaths.upgradeScriptURL,
    ].compactMap { $0 }

    guard let scriptURL = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
      presentInfo(
        title: "Finder Kit",
        message: """
        Script de atualização não encontrado.
        Rode no Terminal: finder-kit upgrade
        """
      )
      return
    }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = [scriptURL.path]
    do {
      try task.run()
    } catch {
      presentInfo(title: "Finder Kit", message: error.localizedDescription)
    }
  }

  private func presentInfo(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}
