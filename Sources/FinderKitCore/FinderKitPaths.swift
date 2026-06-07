import Foundation

public enum FinderKitPaths {
    public static let bundleIdentifier = "com.alexandredias.finder-kit"
    public static let extensionBundleIdentifier = "com.alexandredias.finder-kit.finder-sync"
    public static let appName = "FinderKit"

    public static var installedAppURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("\(appName).app", isDirectory: true)
    }
}
