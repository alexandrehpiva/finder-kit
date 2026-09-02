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
2. Extensão lê `FIFinderSyncController.default().selectedItemURLs()` e abre `finderkit://analyze?path=…`
3. Host **sem sandbox** roda `FolderAnalyzer.analyze` e mostra `NSAlert` (não na extensão — senão o Finder trava e, em `/Volumes`, a enumeração sandboxed volta **0 bytes / 0 arquivos** sem erro)

## Fluxo “Abrir no Obsidian”

1. Menu em pasta selecionada (`.contextualMenuForItems`) **ou** fundo da janela (`.contextualMenuForContainer` → `targetedURL()`)
2. Extensão (sandbox) abre deep link `finderkit://open-obsidian?path=…`
3. Host sem sandbox recebe o URL e executa `ObsidianOpener` → `/usr/bin/open -a Obsidian.app <pasta>`
4. CLI espelha: `finder-kit open-obsidian <pasta>`

## Fluxo “Copiar caminho”

1. Mesmos gatilhos de menu que Obsidian (item ou fundo da janela)
2. Extensão abre `finderkit://copy-path?path=…` (várias pastas: paths com `\n`)
3. Host copia para `NSPasteboard.general`
4. CLI: `finder-kit copy-path <pasta>`

## Logs

- Core: `FinderKitLog` (JSONL, 1 MiB, rotação `.1`)
- Pasta: `~/Library/Group Containers/group.com.alexandredias.finder-kit/tmp/logs/`
- App Group `group.com.alexandredias.finder-kit` no host e na extensão
- CLI: `finder-kit logs`

## Evolução futura

- Novos itens de menu → `FinderKitExtension/FinderSync.swift`
- Lógica nova → `Sources/FinderKitCore/`
- UI dedicada (progresso) → host app SwiftUI + IPC com extensão (App Group)

## Padrão alinhado a `bot-wake`

- SPM + Makefile + `VERSION`
- CLI em `~/.local/bin`
- App em `~/Applications/`
- Core testável, subprocessos/UI finos nas bordas
