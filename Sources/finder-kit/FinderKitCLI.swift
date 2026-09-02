import ArgumentParser
import AppKit
import FinderKitCore
import Foundation

@main
struct FinderKitCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "finder-kit",
    abstract: "Utilitários Finder Kit (análise de pastas, etc.).",
    subcommands: [Analyze.self, OpenObsidian.self, CopyPath.self, Upgrade.self]
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
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    let stats = try FolderAnalyzer.analyze(at: url, skipsHiddenFiles: !includeHidden)
    print(stats.rootURL.lastPathComponent)
    print(stats.summaryLine)
    print("bytes=\(stats.totalBytes)")
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
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    try ObsidianOpener.openFolder(at: url)
    print("Aberto no Obsidian: \(url.path)")
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
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
    let posix = try FolderPathClipboard.posixPath(of: url)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(posix, forType: .string)
    print(posix)
  }
}
