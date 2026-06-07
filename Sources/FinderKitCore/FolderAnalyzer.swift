import Foundation

public enum FolderAnalyzer {
  private static let resourceKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .isDirectoryKey,
    .fileSizeKey,
    .totalFileAllocatedSizeKey,
  ]

  /// Varre a árvore da pasta (inclui subpastas). `skipsHiddenFiles` reduz ruído no Finder.
  public static func analyze(
    at rootURL: URL,
    skipsHiddenFiles: Bool = true
  ) throws -> FolderStats {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &isDirectory),
          isDirectory.boolValue
    else {
      throw FinderKitError.notADirectory(rootURL)
    }

    var fileCount = 0
    var directoryCount = 0
    var totalBytes: Int64 = 0

    let options: FileManager.DirectoryEnumerationOptions = skipsHiddenFiles
      ? [.skipsHiddenFiles]
      : []

    guard let enumerator = FileManager.default.enumerator(
      at: rootURL,
      includingPropertiesForKeys: Array(resourceKeys),
      options: options
    ) else {
      throw FinderKitError.enumerationFailed(rootURL, underlying: CocoaError(.fileReadUnknown))
    }

    while let itemURL = enumerator.nextObject() as? URL {
      let values: URLResourceValues
      do {
        values = try itemURL.resourceValues(forKeys: resourceKeys)
      } catch {
        continue
      }

      if values.isDirectory == true {
        directoryCount += 1
        continue
      }

      if values.isRegularFile == true {
        fileCount += 1
        let bytes = values.totalFileAllocatedSize ?? values.fileSize ?? 0
        totalBytes += Int64(bytes)
      }
    }

    let stats = FolderStats(
      rootURL: rootURL,
      fileCount: fileCount,
      directoryCount: directoryCount,
      totalBytes: totalBytes
    )

    if stats.isEmpty, hasVisibleChildren(at: rootURL, skipsHiddenFiles: skipsHiddenFiles) {
      throw FinderKitError.sandboxAccessDenied(rootURL)
    }

    return stats
  }

  private static func hasVisibleChildren(
    at rootURL: URL,
    skipsHiddenFiles: Bool
  ) -> Bool {
    let options: FileManager.DirectoryEnumerationOptions = skipsHiddenFiles
      ? [.skipsHiddenFiles]
      : []
    guard let children = try? FileManager.default.contentsOfDirectory(
      at: rootURL,
      includingPropertiesForKeys: nil,
      options: options
    ) else {
      return false
    }
    return !children.isEmpty
  }
}
