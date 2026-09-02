import ArgumentParser
import AppKit
import FinderKitCore
import Foundation

@main
struct FinderKitCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "finder-kit",
    abstract: "Utilitários Finder Kit (análise de pastas, etc.).",
    subcommands: [Analyze.self, OpenObsidian.self, CopyPath.self, Logs.self, Upgrade.self]
  )
}

struct Analyze: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "analyze",
    abstract: "Calcula tamanho total e quantidade de arquivos de uma pasta."
  )

  @Argument(help: "Caminho da pasta.")
  var path: String

  @Flag(name: .long, help: "Inclui arquivos ocultos.")
  var includeHidden: Bool = false

  func run() throws {
    FinderKitLog.shared.installCrashReporting(source: .cli)
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    FinderKitLog.shared.info("cli.analyze.start", source: .cli, fields: ["path": url.path])
    do {
      let stats = try FolderAnalyzer.analyze(at: url, skipsHiddenFiles: !includeHidden)
      FinderKitLog.shared.info(
        "cli.analyze.ok",
        source: .cli,
        fields: ["path": url.path, "bytes": String(stats.totalBytes)]
      )
      print(stats.rootURL.lastPathComponent)
      print(stats.summaryLine)
      print("bytes=\(stats.totalBytes)")
    } catch {
      FinderKitLog.shared.error(
        "cli.analyze.fail",
        source: .cli,
        fields: ["path": url.path, "error": error.localizedDescription]
      )
      throw error
    }
  }
}

struct OpenObsidian: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "open-obsidian",
    abstract: "Abre a pasta no Obsidian (`open -a Obsidian <pasta>`)."
  )

  @Argument(help: "Caminho da pasta (ex.: vault ou course root).")
  var path: String

  func run() throws {
    FinderKitLog.shared.installCrashReporting(source: .cli)
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    FinderKitLog.shared.info("cli.obsidian.start", source: .cli, fields: ["path": url.path])
    do {
      try ObsidianOpener.openFolder(at: url)
      FinderKitLog.shared.info("cli.obsidian.ok", source: .cli, fields: ["path": url.path])
      print("Aberto no Obsidian: \(url.path)")
    } catch {
      FinderKitLog.shared.error(
        "cli.obsidian.fail",
        source: .cli,
        fields: ["path": url.path, "error": error.localizedDescription]
      )
      throw error
    }
  }
}

struct CopyPath: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "copy-path",
    abstract: "Copia o caminho absoluto da pasta para o clipboard."
  )

  @Argument(help: "Caminho da pasta.")
  var path: String

  func run() throws {
    FinderKitLog.shared.installCrashReporting(source: .cli)
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    do {
      let posix = try FolderPathClipboard.posixPath(of: url)
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(posix, forType: .string)
      FinderKitLog.shared.info("cli.copy_path.ok", source: .cli, fields: ["path": posix])
      print(posix)
    } catch {
      FinderKitLog.shared.error("cli.copy_path.fail", source: .cli, fields: ["error": error.localizedDescription])
      throw error
    }
  }
}

struct Logs: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "logs",
    abstract: "Mostra o caminho do log JSONL local (máx. 1 MiB)."
  )

  func run() {
    FinderKitLog.shared.installCrashReporting(source: .cli)
    print(FinderKitLog.shared.directoryURL.path)
    print(FinderKitLog.shared.currentFileURL.path)
  }
}
