import Foundation

/// Deep links do host `FinderKit.app` (a extensão sandboxed encaminha ações aqui).
public enum FinderKitDeepLink {
    public static let scheme = "finderkit"
    public static let openObsidianHost = "open-obsidian"
    public static let copyPathHost = "copy-path"

    public enum Action: Equatable, Sendable {
        case openObsidian(folderPath: String)
        case copyPath(folderPath: String)
    }

    /// `finderkit://open-obsidian?path=/caminho/absoluto`
    public static func makeOpenObsidianURL(folderPath: String) -> URL {
        makeURL(host: openObsidianHost, folderPath: folderPath)
    }

    public static func makeOpenObsidianURL(folderURL: URL) -> URL {
        makeOpenObsidianURL(folderPath: folderURL.path)
    }

    /// `finderkit://copy-path?path=/caminho/absoluto` (várias pastas: paths separados por `\n`)
    public static func makeCopyPathURL(folderPath: String) -> URL {
        makeURL(host: copyPathHost, folderPath: folderPath)
    }

    public static func makeCopyPathURL(folderURL: URL) -> URL {
        makeCopyPathURL(folderPath: folderURL.path)
    }

    public static func parse(_ url: URL) -> Action? {
        guard url.scheme?.lowercased() == scheme else { return nil }

        let host = (url.host ?? "").lowercased()
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let path = items.first(where: { $0.name == "path" })?.value,
              !path.isEmpty
        else {
            return nil
        }

        switch host {
        case openObsidianHost:
            return .openObsidian(folderPath: path)
        case copyPathHost:
            return .copyPath(folderPath: path)
        default:
            return nil
        }
    }

    private static func makeURL(host: String, folderPath: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: "path", value: folderPath)]
        guard let url = components.url else {
            preconditionFailure("URLComponents deveria produzir URL válida para \(host)")
        }
        return url
    }
}
