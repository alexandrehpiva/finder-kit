import Foundation

public enum FinderKitError: Error, LocalizedError, Sendable {
    case notADirectory(URL)
    case enumerationFailed(URL, underlying: Error)
    case noSelection
    case sandboxAccessDenied(URL)
    case releaseCheckFailed(String)
    case upgradeFailed(String)
    case obsidianNotFound
    case obsidianOpenFailed(String)

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
        case .releaseCheckFailed(let reason):
            return "Não foi possível verificar atualizações: \(reason)"
        case .upgradeFailed(let reason):
            return "Falha ao atualizar: \(reason)"
        case .obsidianNotFound:
            return """
            Obsidian.app não encontrado em /Applications nem em ~/Applications.
            Instale o Obsidian ou mova o .app para uma dessas pastas.
            """
        case .obsidianOpenFailed(let reason):
            return "Não foi possível abrir a pasta no Obsidian: \(reason)"
        }
    }
}
