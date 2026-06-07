import ArgumentParser
import FinderKitCore
import Foundation

@main
struct FinderKitCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "finder-kit",
        abstract: "Utilitários Finder Kit (análise de pastas, etc.).",
        subcommands: [Analyze.self]
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
