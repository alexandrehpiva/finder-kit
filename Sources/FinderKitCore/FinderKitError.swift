import Foundation

public enum FinderKitError: Error, LocalizedError, Sendable {
    case notADirectory(URL)
    case enumerationFailed(URL, underlying: Error)
    case noSelection
    case sandboxAccessDenied(URL)

    public var errorDescription: String? {
        switch self {
        case .notADirectory(let url):
            return "“\(url.lastPathComponent)” não é uma pasta."
        case .enumerationFailed(let url, let underlying):
            return "Não foi possível ler “\(url.path)”: \(underlying.localizedDescription)"
        case .noSelection:
            return "Nenhuma pasta selecionada."
        case .sandboxAccessDenied(let url):
            return """
            Sem permissão para ler o conteúdo de “\(url.lastPathComponent)”.
            Reative a extensão FinderKit nos Ajustes do Sistema ou reinstale o app.
            """
        }
    }
}
