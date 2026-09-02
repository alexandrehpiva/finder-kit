import FinderKitCore
import Foundation
import Testing

@Suite("FolderPathClipboard")
struct FolderPathClipboardTests {
    @Test("Given pasta, When posixPath, Then path absoluto")
    func posixPathOfDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-clip-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let path = try FolderPathClipboard.posixPath(of: root)
        #expect(path == root.standardizedFileURL.path)
        #expect(!path.hasSuffix("/"))
    }

    @Test("Given duas pastas, When posixPaths, Then linhas")
    func posixPathsJoined() throws {
        let a = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-clip-a-\(UUID().uuidString)", isDirectory: true)
        let b = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-clip-b-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: a)
            try? FileManager.default.removeItem(at: b)
        }

        let text = try FolderPathClipboard.posixPaths(of: [a, b])
        #expect(text == "\(a.standardizedFileURL.path)\n\(b.standardizedFileURL.path)")
    }

    @Test("Given arquivo, When posixPath, Then notADirectory")
    func rejectsFile() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-clip-file-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: file.path, contents: Data("x".utf8))
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(throws: FinderKitError.self) {
            try FolderPathClipboard.posixPath(of: file)
        }
    }
}
