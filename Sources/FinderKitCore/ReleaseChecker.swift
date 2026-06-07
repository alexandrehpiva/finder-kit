import Foundation

public struct GitHubRelease: Decodable, Sendable, Equatable {
  public let tagName: String
  public let assets: [Asset]

  enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case assets
  }

  public struct Asset: Decodable, Sendable, Equatable {
    public let name: String
    public let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
      case name
      case browserDownloadURL = "browser_download_url"
    }
  }

  public var version: String {
    tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
  }

  public var appZipAsset: Asset? {
    assets.first { $0.name.hasPrefix("FinderKit-") && $0.name.hasSuffix(".zip") }
  }
}

public enum ReleaseChecker {
  public static let defaultRepository = "alexandrehpiva/finder-kit"

  public static func fetchLatestRelease(
    repository: String = defaultRepository,
    session: URLSession = .shared
  ) async throws -> GitHubRelease {
    let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    var request = URLRequest(url: url)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("FinderKit", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw FinderKitError.releaseCheckFailed("Resposta inválida do GitHub.")
    }
    guard (200 ... 299).contains(http.statusCode) else {
      throw FinderKitError.releaseCheckFailed("GitHub retornou HTTP \(http.statusCode).")
    }

    let decoder = JSONDecoder()
    let release = try decoder.decode(GitHubRelease.self, from: data)
    guard release.appZipAsset != nil else {
      throw FinderKitError.releaseCheckFailed("Release sem asset FinderKit-*.zip.")
    }
    return release
  }

  public static func isNewer(latest: String, than current: String) -> Bool {
    SemVer.compare(latest, current) == .orderedDescending
  }
}
