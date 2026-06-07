import AppKit
import FinderKitCore
import SwiftUI

struct SettingsView: View {
  private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"

  var body: some View {
    Form {
      Section("Finder Kit") {
        LabeledContent("Versão", value: version)
        LabeledContent("App", value: FinderKitPaths.installedAppURL.path)

        HStack {
          Button("Verificar atualizações") {
            Task { await UpdateCoordinator.shared.checkForUpdates(interactive: true) }
          }
          Button("Atualizar agora") {
            UpdateCoordinator.shared.runUpgradeScript()
          }
        }
      }

      Section("Extensão do Finder") {
        Text(
          """
          Ajustes do Sistema → Geral → Itens de Início de Sessão e Extensões → \
          (i) Extensões do Finder → FinderKit
          """
        )
        .fixedSize(horizontal: false, vertical: true)

        Button("Abrir Ajustes de Extensões") {
          let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Extensions")!
          NSWorkspace.shared.open(url)
        }
      }

      Section("CLI") {
        Text("finder-kit analyze ~/Downloads")
        Text("finder-kit upgrade")
          .font(.body.monospaced())
      }
    }
    .formStyle(.grouped)
    .frame(width: 520, height: 340)
    .padding()
  }
}
