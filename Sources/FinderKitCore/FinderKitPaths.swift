import Foundation

public enum FinderKitPaths {
  public static let bundleIdentifier = "com.alexandredias.finder-kit"
  public static let extensionBundleIdentifier = "com.alexandredias.finder-kit.finder-sync"
  public static let appName = "FinderKit"
  public static let shareDirectoryName = "finder-kit"

  /// `/Applications` tem prioridade sobre `~/Applications` (instalação típica via zip).
  public static func resolveInstalledAppURL(fileManager: FileManager = .default) -> URL? {
    let candidates = [
      URL(fileURLWithPath: "/Applications", isDirectory: true)
        .appendingPathComponent("\(appName).app", isDirectory: true),
      fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications", isDirectory: true)
        .appendingPathComponent("\(appName).app", isDirectory: true),
    ]
    return candidates.first { fileManager.fileExists(atPath: $0.path) }
  }

  public static var installedAppURL: URL {
    resolveInstalledAppURL() ?? defaultInstallURL
  }

  public static var defaultInstallURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Applications", isDirectory: true)
      .appendingPathComponent("\(appName).app", isDirectory: true)
  }

  public static var sharedSupportURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".local/share/\(shareDirectoryName)", isDirectory: true)
  }

  public static var logDirectoryURL: URL {
    FinderKitLog.defaultDirectory()
  }

  public static var upgradeScriptURL: URL {
    sharedSupportURL.appendingPathComponent("upgrade.sh")
  }

  public static var appexURL: URL {
    installedAppURL
      .appendingPathComponent("Contents/PlugIns/FinderKitExtension.appex", isDirectory: true)
  }

  public static func readInstalledVersion(fileManager: FileManager = .default) -> String? {
    guard let appURL = resolveInstalledAppURL(fileManager: fileManager) else { return nil }
    let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
    guard let dict = NSDictionary(contentsOf: plistURL) as? [String: Any] else { return nil }
    return dict["CFBundleShortVersionString"] as? String
  }
}
