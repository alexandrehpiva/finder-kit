import Foundation

/// Path POSIX absoluto de uma pasta (para clipboard / CLI).
public enum FolderPathClipboard {
    public static func posixPath(
        of folderURL: URL,
        fileManager: FileManager = .default
    ) throws -> String {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw FinderKitError.notADirectory(folderURL)
        }
        return folderURL.standardizedFileURL.path
    }

    /// Várias pastas: um path por linha (ordem preservada).
    public static func posixPaths(
        of folderURLs: [URL],
        fileManager: FileManager = .default
    ) throws -> String {
        guard !folderURLs.isEmpty else {
            throw FinderKitError.noSelection
        }
        let paths = try folderURLs.map { try posixPath(of: $0, fileManager: fileManager) }
        return paths.joined(separator: "\n")
    }
}
