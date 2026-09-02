import FinderKitCore
import Foundation
import Testing

private struct RecordingRunner: ProcessRunning, @unchecked Sendable {
    final class State: @unchecked Sendable {
        var executable: URL?
        var arguments: [String] = []
    }

    let state = State()

    func run(executable: URL, arguments: [String]) throws {
        state.executable = executable
        state.arguments = arguments
    }
}

@Suite("ObsidianOpener")
struct ObsidianOpenerTests {
    @Test("Given pasta válida e Obsidian.app, When openFolder, Then chama /usr/bin/open -a Obsidian pasta")
    func openFolderInvokesOpen() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-obsidian-\(UUID().uuidString)", isDirectory: true)
        let apps = root.appendingPathComponent("Apps", isDirectory: true)
        let folder = root.appendingPathComponent("vault", isDirectory: true)
        let obsidian = apps.appendingPathComponent("Obsidian.app", isDirectory: true)

        try FileManager.default.createDirectory(at: apps, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: obsidian, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let runner = RecordingRunner()
        try ObsidianOpener.openFolder(at: folder, searchRoots: [apps], runner: runner)

        #expect(runner.state.executable?.path == "/usr/bin/open")
        #expect(runner.state.arguments == ["-a", obsidian.path, folder.path])
    }

    @Test("Given sem Obsidian.app nas roots, When openFolder, Then obsidianNotFound")
    func missingObsidian() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-obsidian-missing-\(UUID().uuidString)", isDirectory: true)
        let apps = root.appendingPathComponent("Apps", isDirectory: true)
        let folder = root.appendingPathComponent("vault", isDirectory: true)
        try FileManager.default.createDirectory(at: apps, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(throws: FinderKitError.self) {
            try ObsidianOpener.openFolder(at: folder, searchRoots: [apps], runner: RecordingRunner())
        }
    }

    @Test("Given arquivo (não pasta), When openFolder, Then notADirectory")
    func rejectsFile() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-obsidian-file-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: file.path, contents: Data("x".utf8))
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(throws: FinderKitError.self) {
            try ObsidianOpener.openFolder(at: file, searchRoots: [], runner: RecordingRunner())
        }
    }
}

@Suite("FinderKitDeepLink")
struct FinderKitDeepLinkTests {
    @Test("Given path com espaços, When make+parse, Then path round-trip")
    func roundTripPathWithSpaces() {
        let path = "/Volumes/SSD Externo - Ale/Estudos-Alexandre/FIAP/Dev-Leadership"
        let url = FinderKitDeepLink.makeOpenObsidianURL(folderPath: path)
        #expect(url.scheme == "finderkit")
        #expect(url.host == "open-obsidian")
        let action = FinderKitDeepLink.parse(url)
        #expect(action == .openObsidian(folderPath: path))
    }

    @Test("Given path, When makeCopyPath+parse, Then copyPath round-trip")
    func copyPathRoundTrip() {
        let path = "/Volumes/SSD Externo - Ale/Estudos-Alexandre/FIAP/Dev-Leadership"
        let url = FinderKitDeepLink.makeCopyPathURL(folderPath: path)
        #expect(url.host == "copy-path")
        #expect(FinderKitDeepLink.parse(url) == .copyPath(folderPath: path))
    }

    @Test("Given URL de outro scheme, When parse, Then nil")
    func rejectsOtherScheme() {
        let url = URL(string: "https://example.com/open-obsidian?path=/tmp")!
        #expect(FinderKitDeepLink.parse(url) == nil)
    }
}
