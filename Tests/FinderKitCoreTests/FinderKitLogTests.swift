import FinderKitCore
import Foundation
import Testing

@Suite("FinderKitLog")
struct FinderKitLogTests {
    @Test("Given eventos, When write, Then JSONL contém ts level source event")
    func writesStructuredJSONLine() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-log-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = FinderKitLog(
            configuration: .init(directory: dir, maxFileBytes: FinderKitLog.maxFileBytes)
        )
        logger.info("analyze.ok", source: .cli, fields: ["path": "/tmp/vault", "bytes": "12"])
        logger.flush()

        let data = try Data(contentsOf: dir.appendingPathComponent(FinderKitLog.fileName))
        let line = String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
            .map(String.init)
            .first ?? ""
        #expect(line.contains("\"event\":\"analyze.ok\""))
        #expect(line.contains("\"level\":\"info\""))
        #expect(line.contains("\"source\":\"cli\""))
        #expect(line.contains("\"path\":\"\\/tmp\\/vault\"") || line.contains("\"path\":\"/tmp/vault\""))
        #expect(line.contains("\"ts\":"))
        #expect(line.contains("\"pid\":"))
    }

    @Test("Given arquivo no limite, When append excede 1 unidade, Then roda e o atual fica abaixo do máximo")
    func rotatesWhenExceedingMaxFileBytes() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("finder-kit-log-rot-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let maxBytes = 400
        let logger = FinderKitLog(
            configuration: .init(directory: dir, maxFileBytes: maxBytes)
        )
        for index in 0 ..< 40 {
            logger.info("pad.\(index)", source: .core, fields: ["blob": String(repeating: "x", count: 40)])
        }
        logger.flush()

        let current = dir.appendingPathComponent(FinderKitLog.fileName)
        let rotated = dir.appendingPathComponent(FinderKitLog.rotatedFileName)
        let currentSize = try FileManager.default.attributesOfItem(atPath: current.path)[.size] as! NSNumber
        #expect(currentSize.intValue <= maxBytes)
        #expect(FileManager.default.fileExists(atPath: rotated.path))
    }
}
