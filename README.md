# Finder Kit

Utilitário macOS genérico para incrementos no **Finder**. Funcionalidades no menu contextual (botão direito):

- **Finder Kit — Calcular tamanho…** → tamanho total estimado, arquivos e subpastas (em pastas selecionadas)
- **Abrir no Obsidian** → abre a pasta selecionada (ou o fundo da janela) no Obsidian
- **Copiar caminho** → path POSIX no clipboard (várias pastas: um por linha)

Arquitetura: host + extensão Finder Sync; ações bloqueadas pelo sandbox (abrir apps, **calcular tamanho** em volumes externos) passam pelo host via `finderkit://`.

## Requisitos

- macOS 14+
- Xcode 15+ (Command Line Tools + `xcodebuild`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Swift 5.9+

## Atualizar

```bash
finder-kit upgrade
```

Ou: o app verifica o GitHub ao iniciar e pergunta se deseja atualizar (v1.2.0+).

No fim o script pergunta se deseja **reiniciar as janelas do Finder** (`killall Finder`). Sem perguntar: `finder-kit upgrade --restart-finder`.

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

1. Botão direito em uma **pasta** (ou no **fundo** da janela aberta)
2. **Finder Kit — Calcular tamanho…** (só em pasta selecionada), **Abrir no Obsidian** e/ou **Copiar caminho**
3. Obsidian: equivalente a `open -a Obsidian "/caminho/da/pasta"` (o host FinderKit precisa estar instalado)

### CLI (teste / automação)

```bash
finder-kit analyze ~/Downloads
finder-kit analyze ~/Projects --include-hidden
finder-kit open-obsidian "/Volumes/SSD Externo - Ale/Estudos-Alexandre/FIAP/Dev-Leadership"
finder-kit copy-path ~/Downloads
finder-kit logs
```

### Logs (v1.3.3+)

JSON Lines em:

`~/Library/Group Containers/group.com.alexandredias.finder-kit/tmp/logs/finder-kit.jsonl`

Máximo **1 MiB**; o arquivo anterior vira `finder-kit.jsonl.1`. Inclui ações do menu, CLI, host e `NSException` (`crash.ns_exception`).


## Desinstalar

```bash
make uninstall
```

## Desenvolvimento

```bash
make setup-hooks   # uma vez: pre-commit + gitleaks (bloqueia segredos no commit)
make test          # testes SPM (FinderKitCore)
make build-cli     # só CLI
make build-app     # app + extensão via Xcode
make clean
```

### Segurança (pre-commit)

```bash
brew install pre-commit   # se ainda não tiver
make setup-hooks
```

Cada `git commit` roda **gitleaks** nos arquivos staged. Para pular em emergência: `SKIP=gitleaks git commit ...`

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
