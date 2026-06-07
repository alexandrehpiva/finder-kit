.PHONY: build build-cli build-app test install install-cli install-app uninstall clean xcodeproj

VERSION := $(shell tr -d ' \n' < VERSION)
BINARY_NAME = finder-kit
INSTALL_DIR = $(HOME)/.local/bin
APPS_DIR = $(HOME)/Applications
APP_NAME = FinderKit
APP_BUNDLE = $(APPS_DIR)/$(APP_NAME).app
RELEASE_DIR = .build/release
DERIVED_DATA = build/DerivedData
XCODE_PRODUCTS = $(DERIVED_DATA)/Build/Products/Release
EXTENSION_APPEX = $(APP_BUNDLE)/Contents/PlugIns/FinderKitExtension.appex

build: build-cli build-app

build-cli:
	swift build -c release

xcodeproj:
	@command -v xcodegen >/dev/null 2>&1 || { \
		echo "xcodegen não encontrado. Instale com: brew install xcodegen"; \
		exit 1; \
	}
	xcodegen generate

build-app: xcodeproj
	xcodebuild \
		-project FinderKit.xcodeproj \
		-scheme FinderKit \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		build

test:
	swift test

install: build install-cli install-app register-extension
	@echo ""
	@echo "Finder Kit $(VERSION) instalado:"
	@echo "  CLI:  $(INSTALL_DIR)/$(BINARY_NAME)"
	@echo "  App:  $(APP_BUNDLE)"
	@echo "  Ative a extensão: Ajustes → Extensões → Finder → Finder Kit"

install-cli:
	@mkdir -p $(INSTALL_DIR)
	install -m 755 $(RELEASE_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)

install-app:
	@mkdir -p $(APPS_DIR)
	rm -rf $(APP_BUNDLE)
	cp -R $(XCODE_PRODUCTS)/$(APP_NAME).app $(APP_BUNDLE)
	codesign --force --deep --sign - $(APP_BUNDLE)

register-extension:
	@if [ -d "$(EXTENSION_APPEX)" ]; then \
		pluginkit -a "$(EXTENSION_APPEX)" 2>/dev/null || true; \
		echo "Extensão registrada (pluginkit)."; \
	else \
		echo "aviso: $(EXTENSION_APPEX) não encontrado"; \
	fi

uninstall:
	-pluginkit -r "$(EXTENSION_APPEX)" 2>/dev/null
	rm -rf $(APP_BUNDLE)
	rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Finder Kit desinstalado."

clean:
	swift package clean
	rm -rf $(DERIVED_DATA) build
