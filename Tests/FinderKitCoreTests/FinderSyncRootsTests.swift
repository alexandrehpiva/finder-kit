import FinderKitCore
import Foundation
import Testing

@Suite("FinderSyncRoots")
struct FinderSyncRootsTests {
    @Test("Given volumes montados, When directoryURLs, Then inclui raiz e cada volume")
    func includesRootAndMountedVolumes() {
        let urls = FinderSyncRoots.directoryURLs()
        let paths = Set(urls.map(\.standardizedFileURL.path))
        #expect(paths.contains("/"))
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) ?? []
        for volume in volumes {
            #expect(paths.contains(volume.standardizedFileURL.path))
        }
    }
}
