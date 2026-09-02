import Foundation

/// Log estruturado (JSON Lines) para host, extensão Finder Sync e CLI.
///
/// Pasta local temporária compartilhada (App Group):
/// `~/Library/Group Containers/group.com.alexandredias.finder-kit/tmp/logs/`
/// Arquivo atual `finder-kit.jsonl` — no máximo 1 MiB; o giro anterior é `finder-kit.jsonl.1`.
public final class FinderKitLog: @unchecked Sendable {
    public static let applicationGroupID = "group.com.alexandredias.finder-kit"
    public static let maxFileBytes = 1_048_576
    public static let fileName = "finder-kit.jsonl"
    public static let rotatedFileName = "finder-kit.jsonl.1"

    public static let shared = FinderKitLog()

    public enum Source: String, Codable, Sendable {
        case core
        case appex
        case host
        case cli
    }

    public enum Level: String, Codable, Sendable {
        case debug
        case info
        case warn
        case error
        case fault
    }

    public struct Configuration: Sendable {
        public var directory: URL
        public var maxFileBytes: Int
        public var fileName: String
        public var rotatedFileName: String

        public init(
            directory: URL,
            maxFileBytes: Int = FinderKitLog.maxFileBytes,
            fileName: String = FinderKitLog.fileName,
            rotatedFileName: String = FinderKitLog.rotatedFileName
        ) {
            self.directory = directory
            self.maxFileBytes = max(1, maxFileBytes)
            self.fileName = fileName
            self.rotatedFileName = rotatedFileName
        }
    }

    private let queue = DispatchQueue(label: "com.alexandredias.finder-kit.log")
    private let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private var configuration: Configuration
    private var fileHandle: FileHandle?
    private var crashHooksInstalled = false

    public init(configuration: Configuration? = nil) {
        self.configuration = configuration ?? Configuration(directory: Self.defaultDirectory())
    }

    public static func defaultDirectory(fileManager: FileManager = .default) -> URL {
        if let container = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: applicationGroupID
        ) {
            return container.appendingPathComponent("tmp/logs", isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Group Containers/\(applicationGroupID)/tmp/logs",
                isDirectory: true
            )
    }

    public var directoryURL: URL {
        queue.sync { configuration.directory }
    }

    public var currentFileURL: URL {
        directoryURL.appendingPathComponent(configuration.fileName)
    }

    public func replaceConfiguration(_ configuration: Configuration) {
        queue.sync {
            try? fileHandle?.close()
            fileHandle = nil
            self.configuration = configuration
        }
    }

    public func info(_ event: String, source: Source, fields: [String: String] = [:]) {
        write(level: .info, event: event, source: source, fields: fields)
    }

    public func warn(_ event: String, source: Source, fields: [String: String] = [:]) {
        write(level: .warn, event: event, source: source, fields: fields)
    }

    public func error(_ event: String, source: Source, fields: [String: String] = [:]) {
        write(level: .error, event: event, source: source, fields: fields)
    }

    public func fault(_ event: String, source: Source, fields: [String: String] = [:]) {
        write(level: .fault, event: event, source: source, fields: fields)
        flush()
    }

    public func write(level: Level, event: String, source: Source, fields: [String: String] = [:]) {
        let record = Record(
            ts: iso8601.string(from: Date()),
            level: level.rawValue,
            source: source.rawValue,
            event: event,
            pid: ProcessInfo.processInfo.processIdentifier,
            process: ProcessInfo.processInfo.processName,
            fields: fields
        )
        guard let line = record.jsonLine() else { return }
        queue.sync {
            appendUnlocked(line)
            try? fileHandle?.synchronize()
        }
    }

    public func flush() {
        queue.sync {
            try? fileHandle?.synchronize()
        }
    }

    /// NSException → linha `fault` + flush. Sem signal handlers (inseguros na extensão).
    public func installCrashReporting(source: Source) {
        let alreadyInstalled: Bool = queue.sync {
            if crashHooksInstalled { return true }
            crashHooksInstalled = true
            return false
        }
        guard !alreadyInstalled else { return }

        finderKitPreviousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler { exception in
            FinderKitLog.shared.fault(
                "crash.ns_exception",
                source: .core,
                fields: [
                    "name": exception.name.rawValue,
                    "reason": exception.reason ?? "",
                    "stack": exception.callStackSymbols.prefix(12).joined(separator: " | "),
                ]
            )
            finderKitPreviousExceptionHandler?(exception)
        }
        write(level: .info, event: "log.crash_hooks_installed", source: source, fields: [:])
    }

    private func appendUnlocked(_ line: String) {
        do {
            try FileManager.default.createDirectory(
                at: configuration.directory,
                withIntermediateDirectories: true
            )
            let url = configuration.directory.appendingPathComponent(configuration.fileName)
            var payload = Data(line.utf8)
            payload.append(0x0A)
            if payload.count > configuration.maxFileBytes {
                payload = Data(payload.prefix(configuration.maxFileBytes))
            }

            let currentSize =
                (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?
                .intValue ?? 0
            if currentSize > 0, currentSize + payload.count > configuration.maxFileBytes {
                try? fileHandle?.close()
                fileHandle = nil
                let rotated = configuration.directory.appendingPathComponent(configuration.rotatedFileName)
                try? FileManager.default.removeItem(at: rotated)
                try? FileManager.default.moveItem(at: url, to: rotated)
            }

            if fileHandle == nil {
                if !FileManager.default.fileExists(atPath: url.path) {
                    FileManager.default.createFile(atPath: url.path, contents: nil)
                }
                fileHandle = try FileHandle(forWritingTo: url)
                try fileHandle?.seekToEnd()
            }
            try fileHandle?.write(contentsOf: payload)
        } catch {
            try? fileHandle?.close()
            fileHandle = nil
        }
    }
}

private var finderKitPreviousExceptionHandler: NSUncaughtExceptionHandler?

private struct Record: Encodable {
    let ts: String
    let level: String
    let source: String
    let event: String
    let pid: Int32
    let process: String
    let fields: [String: String]

    func jsonLine() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
