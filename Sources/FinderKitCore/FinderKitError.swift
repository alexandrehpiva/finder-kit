import Foundation

public enum FinderKitError: Error, LocalizedError, Sendable {
    case notADirectory(URL)
    case enumerationFailed(URL, underlying: Error)
    case noSelection

    public var errorDescription: String? {
        switch self {
        case .notADirectory(let url):
            return "“\(url.lastPathComponent)” não é uma pasta."
        case .enumerationFailed(let url, let underlying):
            return "Não foi possível ler “\(url.path)”: \(underlying.localizedDescription)"
        case .noSelection:
            return "Nenhuma pasta selecionada."
        }
    }
}
