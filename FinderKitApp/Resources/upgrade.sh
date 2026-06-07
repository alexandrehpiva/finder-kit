#!/bin/bash
# Atualiza FinderKit.app da última release no GitHub (repo público).
# Uso: upgrade.sh [--version X.Y.Z]
set -euo pipefail

REPO="alexandrehpiva/finder-kit"
APP_NAME="FinderKit"
EXTENSION_ID="com.alexandredias.finder-kit.finder-sync"
PIN_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      PIN_VERSION="${2:-}"
      shift 2
      ;;
    *)
      echo "uso: $0 [--version X.Y.Z]"
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

pluginkit -a "${APP_PATH}/Contents/PlugIns/FinderKitExtension.appex"
pluginkit -e use -i "${EXTENSION_ID}"

open "${APP_PATH}"
sleep 1
killall Finder 2>/dev/null || true

echo "Finder Kit ${VERSION} instalado em ${APP_PATH}"
