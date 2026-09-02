import Foundation

/// Diretórios que o Finder Sync precisa monitorar para o menu aparecer.
/// Só `/` **não** cobre volumes externos (`/Volumes/…`) no macOS recente.
public enum FinderSyncRoots {
    public static func directoryURLs(fileManager: FileManager = .default) -> Set<URL> {
        var urls: Set<URL> = [
            URL(fileURLWithPath: "/", isDirectory: true).standardizedFileURL
        ]
        let volumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) ?? []
        for volume in volumes {
            urls.insert(volume.standardizedFileURL)
        }
        return urls
    }
}
