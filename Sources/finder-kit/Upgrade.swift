import ArgumentParser
import FinderKitCore
import Foundation

struct Upgrade: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "upgrade",
    abstract: "Baixa e instala a última release do GitHub (substitui o app e reativa a extensão)."
  )

  @Flag(name: .long, help: "Só verifica se há versão nova; não instala.")
  var check: Bool = false

  @Option(name: .long, help: "Instala uma versão específica (ex: 1.0.1).")
  var version: String?

  func run() throws {
    FinderKitLog.shared.installCrashReporting(source: .cli)
    if check {
      try runCheckOnly()
      return
    }
    FinderKitLog.shared.info("cli.upgrade.start", source: .cli)
    do {
      try runUpgradeScript()
      FinderKitLog.shared.info("cli.upgrade.ok", source: .cli)
    } catch {
      FinderKitLog.shared.error("cli.upgrade.fail", source: .cli, fields: ["error": error.localizedDescription])
      throw error
    }
  }

  private func runCheckOnly() throws {
    let sema = DispatchSemaphore(value: 0)
    var result: Result<Void, Error> = .success(())
    Task {
      do {
        let current = FinderKitPaths.readInstalledVersion() ?? "0"
        let release = try await ReleaseChecker.fetchLatestRelease()
        if ReleaseChecker.isNewer(latest: release.version, than: current) {
          print("nova versão: \(release.version) (atual: \(current))")
        } else {
          print("atualizado: \(current)")
        }
      } catch {
        result = .failure(error)
      }
      sema.signal()
    }
    sema.wait()
    if case .failure(let error) = result { throw error }
  }

  private func runUpgradeScript() throws {
    let scriptURL = resolveUpgradeScript()
    guard FileManager.default.isExecutableFile(atPath: scriptURL.path) else {
      throw FinderKitError.upgradeFailed("Script não encontrado: \(scriptURL.path)")
    }

    var args = [scriptURL.path]
    if let version {
      args.append(contentsOf: ["--version", version])
    }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = args
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    try task.run()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else {
      throw FinderKitError.upgradeFailed("upgrade.sh saiu com código \(task.terminationStatus)")
    }
  }

  private func resolveUpgradeScript() -> URL {
    let appResources = FinderKitPaths.installedAppURL
      .appendingPathComponent("Contents/Resources/upgrade.sh")

    let candidates = [
      FinderKitPaths.upgradeScriptURL,
      appResources,
      URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("scripts/upgrade.sh"),
    ]
    return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
      ?? FinderKitPaths.upgradeScriptURL
  }
}
