import FinderKitCore
import Foundation
import Testing

@Suite("FolderAnalyzer")
struct FolderAnalyzerTests {
    @Test("conta arquivos e bytes em pasta temporária")
    func analyzeCountsFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let sub = root.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: root.appendingPathComponent("a.txt"))
        try Data("world!".utf8).write(to: sub.appendingPathComponent("b.txt"))

        let stats = try FolderAnalyzer.analyze(at: root)

        #expect(stats.fileCount == 2)
        #expect(stats.directoryCount == 1)
        #expect(stats.totalBytes >= 11)
        #expect(stats.summaryLine.contains("arquivo"))
    }

    @Test("arquivo solto lança notADirectory")
    func analyzeRejectsFile() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-file-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: file.path, contents: Data("x".utf8))
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(throws: FinderKitError.self) {
            try FolderAnalyzer.analyze(at: file)
        }
    }
}
