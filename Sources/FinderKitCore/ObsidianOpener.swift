import Foundation

/// Executa um binário com argumentos (injetável nos testes).
public protocol ProcessRunning: Sendable {
    func run(executable: URL, arguments: [String]) throws
}

public struct ShellProcessRunner: ProcessRunning {
    public init() {}

    public func run(executable: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let data = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw FinderKitError.obsidianOpenFailed(
                message.isEmpty ? "código de saída \(process.terminationStatus)" : message
            )
        }
    }
}

/// Abre uma pasta no Obsidian (`open -a Obsidian.app <pasta>`).
public enum ObsidianOpener {
    /// Locais padrão onde o Obsidian costuma estar instalado.
    public static func defaultObsidianSearchRoots(fileManager: FileManager = .default) -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true),
        ]
    }

    public static func resolveObsidianAppURL(
        fileManager: FileManager = .default,
        searchRoots: [URL]? = nil
    ) -> URL? {
        let roots = searchRoots ?? defaultObsidianSearchRoots(fileManager: fileManager)
        let candidates = roots.map {
            $0.appendingPathComponent("Obsidian.app", isDirectory: true)
        }
        return candidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    public static func openFolder(
        at folderURL: URL,
        fileManager: FileManager = .default,
        searchRoots: [URL]? = nil,
        runner: any ProcessRunning = ShellProcessRunner()
    ) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw FinderKitError.notADirectory(folderURL)
        }

        guard let obsidianApp = resolveObsidianAppURL(
            fileManager: fileManager,
            searchRoots: searchRoots
        ) else {
            throw FinderKitError.obsidianNotFound
        }

        // Equivalente a: open -a "/Applications/Obsidian.app" "/path/da/pasta"
        try runner.run(
            executable: URL(fileURLWithPath: "/usr/bin/open"),
            arguments: ["-a", obsidianApp.path, folderURL.path]
        )
    }
}
