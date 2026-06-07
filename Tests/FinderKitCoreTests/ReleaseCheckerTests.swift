import FinderKitCore
import Foundation
import Testing

@Suite("ReleaseChecker")
struct ReleaseCheckerTests {
  @Test("isNewer compara semver")
  func versionCompare() {
    #expect(ReleaseChecker.isNewer(latest: "1.2.0", than: "1.0.1"))
    #expect(!ReleaseChecker.isNewer(latest: "1.0.1", than: "1.2.0"))
    #expect(!ReleaseChecker.isNewer(latest: "1.2.0", than: "1.2.0"))
  }

  @Test("decodifica release JSON do GitHub")
  func decodeRelease() throws {
    let json = """
    {
      "tag_name": "v1.2.0",
      "assets": [
        {
          "name": "FinderKit-1.2.0.zip",
          "browser_download_url": "https://example.com/FinderKit-1.2.0.zip"
        }
      ]
    }
    """.data(using: .utf8)!

    let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
    #expect(release.version == "1.2.0")
    #expect(release.appZipAsset?.name == "FinderKit-1.2.0.zip")
  }
}
