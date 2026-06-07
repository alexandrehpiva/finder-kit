# Finder Kit

Utilitário macOS genérico para incrementos no **Finder**. A primeira funcionalidade adiciona ao menu contextual (botão direito) em pastas:

**Finder Kit — Calcular tamanho…** → tamanho total estimado, quantidade de arquivos e subpastas.

Arquitetura preparada para novas ações no mesmo app (host + extensão Finder Sync).

## Requisitos

- macOS 14+
- Xcode 15+ (Command Line Tools + `xcodebuild`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Swift 5.9+

## Instalação

### Sem Xcode (release pré-compilada)

1. Baixe `FinderKit-{versão}.zip` em [GitHub Releases](https://github.com/alexandrehpiva/finder-kit/releases)
2. Extraia e mova `FinderKit.app` para `~/Applications`
3. Ative **Ajustes → Extensões → Finder → Finder Kit**
4. Opcional: copie `finder-kit-*-macos-arm64` para `~/.local/bin/finder-kit`

### Com Xcode (desenvolvimento)

```bash
git clone git@github.com:alexandrehpiva/finder-kit.git
cd finder-kit
make install
```

Instala:

| Artefato | Destino |
|----------|---------|
| CLI | `~/.local/bin/finder-kit` |
| App (host + extensão) | `~/Applications/FinderKit.app` |

Depois do `make install`, ative a extensão:

**Ajustes do Sistema → Extensões → Finder → Finder Kit** (ligar).

Reabra o Finder (ou faça logout/login) se o item não aparecer no menu.

## Uso

### Finder

1. Botão direito em uma **pasta**
2. **Finder Kit — Calcular tamanho…**
3. Diálogo com tamanho, arquivos e pastas (varredura recursiva, sem ocultos)

### CLI (teste / automação)

```bash
finder-kit analyze ~/Downloads
finder-kit analyze ~/Projects --include-hidden
```

## Desinstalar

```bash
make uninstall
```

## Desenvolvimento

```bash
make test          # testes SPM (FinderKitCore)
make build-cli     # só CLI
make build-app     # app + extensão via Xcode
make clean
```

### Árvore

```
finder-kit/
├── Package.swift              # FinderKitCore + CLI + testes
├── project.yml                # XcodeGen → app + Finder Sync extension
├── Makefile
├── VERSION
├── Sources/FinderKitCore/     # lógica compartilhada (testável)
├── Sources/finder-kit/        # CLI
├── FinderKitApp/              # host app (Settings, LSUIElement)
├── FinderKitExtension/        # Finder Sync (menu contextual)
├── bundle/                    # Info.plist
├── Tests/
├── Formula/                   # template Homebrew
└── docs/
```

## Versionamento e releases

- Versão canônica: arquivo `VERSION` + tag Git `vX.Y.Z`
- **GitHub Actions** (`release.yml`): tag `v*` → build no `macos-14` → GitHub Releases
- **S3** (opcional): variáveis `S3_RELEASES_BUCKET` e `AWS_RELEASE_ROLE_ARN` — ver `infra/README.md`
- Homebrew: `Formula/finder-kit.rb` (atualizar `sha256` após release)

## Licença

Uso pessoal — Alexandre Dias.
