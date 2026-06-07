# Finder Kit — arquitetura

## Camadas

| Camada | Responsabilidade |
|--------|------------------|
| **FinderKitCore** (SPM) | `FolderAnalyzer`, formatação, erros — sem UI |
| **finder-kit** (CLI) | Automação e testes manuais via terminal |
| **FinderKit.app** (host) | Agente em background (`LSUIElement`), Settings, versionamento |
| **FinderKitExtension.appex** | Finder Sync — itens de menu contextual |

## Por que host app + extensão?

O Finder só carrega **Finder Sync Extensions** embutidas em um `.app` assinado. O host não precisa de janela principal; existe para hospedar a `.appex` e abrir Ajustes.

## Fluxo “Calcular tamanho”

1. Usuário seleciona pasta no Finder → menu contextual
2. Extensão lê `FIFinderSyncController.default().selectedItemURLs()`
3. `FolderAnalyzer.analyze` em background (`DispatchQueue.global`)
4. `NSAlert` na main thread com resultado

## Evolução futura

- Novos itens de menu → `FinderKitExtension/FinderSync.swift`
- Lógica nova → `Sources/FinderKitCore/`
- UI dedicada (progresso) → host app SwiftUI + IPC com extensão (App Group)

## Padrão alinhado a `bot-wake`

- SPM + Makefile + `VERSION`
- CLI em `~/.local/bin`
- App em `~/Applications/`
- Core testável, subprocessos/UI finos nas bordas
