#!/bin/bash
# Atualiza FinderKit.app da última release no GitHub (repo público).
# Uso: upgrade.sh [--version X.Y.Z] [--restart-finder]
set -euo pipefail

REPO="alexandrehpiva/finder-kit"
APP_NAME="FinderKit"
EXTENSION_ID="com.alexandredias.finder-kit.finder-sync"
PIN_VERSION=""
RESTART_FINDER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      PIN_VERSION="${2:-}"
      shift 2
      ;;
    --restart-finder)
      RESTART_FINDER="yes"
      shift
      ;;
    *)
      echo "uso: $0 [--version X.Y.Z] [--restart-finder]"
      exit 1
      ;;
  esac
done

if [[ -d "/Applications/${APP_NAME}.app" ]]; then
  APP_PATH="/Applications/${APP_NAME}.app"
elif [[ -d "${HOME}/Applications/${APP_NAME}.app" ]]; then
  APP_PATH="${HOME}/Applications/${APP_NAME}.app"
else
  echo "erro: ${APP_NAME}.app não encontrado em /Applications nem ~/Applications"
  exit 1
fi

APPEX="${APP_PATH}/Contents/PlugIns/FinderKitExtension.appex"

fetch_release_json() {
  if [[ -n "$PIN_VERSION" ]]; then
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/tags/v${PIN_VERSION}"
  else
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest"
  fi
}

RELEASE_JSON="$(fetch_release_json)"
VERSION="$(python3 -c "import sys,json; t=json.load(sys.stdin)['tag_name']; print(t[1:] if t.startswith('v') else t)" <<<"$RELEASE_JSON")"
ZIP_URL="$(python3 -c "
import sys, json
r = json.load(sys.stdin)
for a in r.get('assets', []):
    n = a.get('name', '')
    if n.startswith('FinderKit-') and n.endswith('.zip'):
        print(a['browser_download_url'])
        break
else:
    sys.exit(1)
" <<<"$RELEASE_JSON")"

echo "Atualizando Finder Kit para ${VERSION}…"

osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
killall "${APP_NAME}" 2>/dev/null || true
killall FinderKitExtension 2>/dev/null || true
pluginkit -r "${APPEX}" 2>/dev/null || true
sleep 1

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

curl -fsSL -o "${TMP}/FinderKit.zip" "${ZIP_URL}"
ditto -x -k "${TMP}/FinderKit.zip" "${TMP}/extract"
NEW_APP="$(find "${TMP}/extract" -name "${APP_NAME}.app" -maxdepth 3 | head -1)"
if [[ -z "$NEW_APP" || ! -d "$NEW_APP" ]]; then
  echo "erro: zip sem ${APP_NAME}.app"
  exit 1
fi

rm -rf "${APP_PATH}"
ditto "${NEW_APP}" "${APP_PATH}"

if xattr -c "${APP_PATH}" 2>/dev/null; then
  :
else
  find "${APP_PATH}" -exec xattr -c {} \; 2>/dev/null || true
fi

# Garante entitlements na .appex (releases antigas com `codesign --deep` sem
# entitlements falhavam no pluginkit — extensão nem aparecia na lista).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXT_ENT="${REPO_ROOT}/FinderKitExtension/FinderKitExtension.entitlements"
HOST_ENT="${REPO_ROOT}/FinderKitApp/FinderKit.entitlements"
if [[ -f "$EXT_ENT" && -f "$HOST_ENT" ]]; then
  codesign --force --sign - --entitlements "$EXT_ENT" --timestamp=none \
    "${APP_PATH}/Contents/PlugIns/FinderKitExtension.appex"
  codesign --force --sign - --entitlements "$HOST_ENT" --timestamp=none \
    "${APP_PATH}"
fi

pluginkit -a "${APP_PATH}/Contents/PlugIns/FinderKitExtension.appex"
pluginkit -e use -i "${EXTENSION_ID}"

SHARE_DIR="${HOME}/.local/share/finder-kit"
mkdir -p "${SHARE_DIR}" "${HOME}/.local/bin"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
DEST="${SHARE_DIR}/upgrade.sh"
if [[ "$SRC" != "$DEST" ]]; then
  install -m 755 "$SRC" "$DEST"
else
  chmod 755 "$DEST"
fi

CLI_URL="$(python3 -c "
import sys, json
r = json.load(sys.stdin)
for a in r.get('assets', []):
    n = a.get('name', '')
    if n.startswith('finder-kit-') and n.endswith('-macos-arm64'):
        print(a['browser_download_url'])
        break
" <<<"$RELEASE_JSON" || true)"
if [[ -n "${CLI_URL}" ]]; then
  curl -fsSL -o "${TMP}/finder-kit" "${CLI_URL}"
  install -m 755 "${TMP}/finder-kit" "${HOME}/.local/bin/finder-kit"
fi

open "${APP_PATH}"
sleep 1

echo "Finder Kit ${VERSION} instalado em ${APP_PATH}"
if pluginkit -m -A 2>/dev/null | grep -q "${EXTENSION_ID}"; then
  echo "Extensão registrada no pluginkit."
else
  echo "aviso: extensão ainda não listada — Ajustes → Geral → Itens de Início e Extensões → (i) Extensões do Finder → ligue FinderKit"
fi

restart_finder_windows() {
  echo "Reiniciando o Finder…"
  /usr/bin/nohup /usr/bin/killall -KILL Finder >/dev/null 2>&1 </dev/null &
  echo "Finder reiniciado."
}

# O CLI Swift (`Process`) coloca o bash noutro process group. Ler o terminal
# (`read < /dev/tty` ou stdin=tty) recebe SIGTTIN e o processo **para** — o `s`
# só aparece por eco do terminal, o script nunca continua. Perguntar via GUI.
prompt_restart_finder() {
  if [[ "${RESTART_FINDER}" == "yes" ]]; then
    restart_finder_windows
    return
  fi
  local btn=""
  btn="$(/usr/bin/osascript -e 'try
  button returned of (display dialog "Reiniciar as janelas do Finder agora?" buttons {"Não", "Sim"} default button "Não" with title "Finder Kit")
on error
  return "Não"
end try' 2>/dev/null || true)"
  if [[ "$btn" == "Sim" ]]; then
    restart_finder_windows
  else
    echo "Ok. Quando quiser: killall -KILL Finder"
  fi
}

prompt_restart_finder
