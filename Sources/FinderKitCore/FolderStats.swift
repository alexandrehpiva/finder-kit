import Foundation

public struct FolderStats: Sendable, Equatable {
    public let rootURL: URL
    public let fileCount: Int
    public let directoryCount: Int
    public let totalBytes: Int64

    public init(rootURL: URL, fileCount: Int, directoryCount: Int, totalBytes: Int64) {
        self.rootURL = rootURL
        self.fileCount = fileCount
        self.directoryCount = directoryCount
        self.totalBytes = totalBytes
    }

    public var formattedSize: String {
        ByteCountFormatter.folderSize.string(fromByteCount: totalBytes)
    }

    public var summaryLine: String {
        "\(formattedSize) · \(fileCount) arquivo(s) · \(directoryCount) pasta(s)"
    }
}
