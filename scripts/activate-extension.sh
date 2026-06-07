#!/bin/bash
# Registra e ativa a extensão Finder Sync após instalar FinderKit.app pelo zip.
set -euo pipefail

APP="/Applications/FinderKit.app"
APPEX="$APP/Contents/PlugIns/FinderKitExtension.appex"
BUNDLE_ID="com.alexandredias.finder-kit.finder-sync"

if [ ! -d "$APPEX" ]; then
  echo "erro: extensão não encontrada em $APPEX"
  echo "      instale FinderKit.app em /Applications primeiro"
  exit 1
fi

pluginkit -a "$APPEX"
pluginkit -e use -i "$BUNDLE_ID"

echo ""
echo "Extensão FinderKit ativada."
echo "Reinicie o Finder: killall Finder"
echo ""
echo "UI (opcional): Ajustes do Sistema → Geral → Itens de Início de Sessão e Extensões"
echo "               → (i) em Extensões do Finder → FinderKit ligado"
