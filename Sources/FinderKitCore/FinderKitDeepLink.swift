import Foundation

/// Deep links do host `FinderKit.app` (a extensão sandboxed encaminha ações aqui).
public enum FinderKitDeepLink {
    public static let scheme = "finderkit"
    public static let openObsidianHost = "open-obsidian"

    public enum Action: Equatable, Sendable {
        case openObsidian(folderPath: String)
    }

    /// `finderkit://open-obsidian?path=/caminho/absoluto`
    public static func makeOpenObsidianURL(folderPath: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = openObsidianHost
        components.queryItems = [URLQueryItem(name: "path", value: folderPath)]
        guard let url = components.url else {
            preconditionFailure("URLComponents deveria produzir URL válida para open-obsidian")
        }
        return url
    }

    public static func makeOpenObsidianURL(folderURL: URL) -> URL {
        makeOpenObsidianURL(folderPath: folderURL.path)
    }

    public static func parse(_ url: URL) -> Action? {
        guard url.scheme?.lowercased() == scheme else { return nil }

        let host = (url.host ?? "").lowercased()
        guard host == openObsidianHost else { return nil }

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let path = items.first(where: { $0.name == "path" })?.value,
              !path.isEmpty
        else {
            return nil
        }
        return .openObsidian(folderPath: path)
    }
}
