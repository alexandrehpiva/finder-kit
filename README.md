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
2. Extraia e mova `FinderKit.app` para **Aplicativos** (`/Applications`) ou `~/Applications` — são pastas diferentes no macOS
3. **Primeira abertura (Gatekeeper):** o app é assinado ad-hoc no CI, sem notarização Apple — ao baixar da internet o macOS pode bloquear. Use **uma** das opções:
   - **Recomendado:** botão direito em `FinderKit.app` → **Abrir** → confirmar **Abrir** no diálogo (só na primeira vez; depois o duplo clique funciona)
   - Ou no Terminal (ajuste o caminho se instalou em `~/Applications`): `xattr -c /Applications/FinderKit.app` (ou `find /Applications/FinderKit.app -exec xattr -c {} \;`) e depois abra com botão direito → **Abrir**
   - Ou, após uma tentativa bloqueada: **Ajustes do Sistema → Privacidade e Segurança → Abrir mesmo assim**
4. Abra o app uma vez (botão direito → **Abrir**)
5. **Ative a extensão** (obrigatório ao instalar pelo zip — o `make install` faz isso automaticamente):

   ```bash
   bash /caminho/para/finder-kit/scripts/activate-extension.sh
   # ou manualmente:
   pluginkit -a "/Applications/FinderKit.app/Contents/PlugIns/FinderKitExtension.appex"
   pluginkit -e use -i com.alexandredias.finder-kit.finder-sync
   killall Finder
   ```

6. **Opcional — conferir nos Ajustes** (macOS Sequoia/Tahoe; o caminho antigo “Extensões → Finder” não existe mais):
   **Ajustes do Sistema → Geral → Itens de Início de Sessão e Extensões** → clique no **(i)** ao lado de **Extensões do Finder** → ligue **FinderKit** (nome exibido, sem espaço)

7. Opcional: copie `finder-kit-*-macos-arm64` para `~/.local/bin/finder-kit` (`chmod +x`)

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

Depois do `make install`, a extensão já é registrada via `pluginkit`. Se o menu não aparecer, rode `killall Finder`.

Para conferir nos Ajustes: **Geral → Itens de Início de Sessão e Extensões → (i) Extensões do Finder → FinderKit**.

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
