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
      }

      Section("Extensão do Finder") {
        Text(
          "Ative em Ajustes do Sistema → Extensões → Finder → Finder Kit."
        )
        .fixedSize(horizontal: false, vertical: true)

        Button("Abrir Ajustes de Extensões") {
          if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Extensions") {
            NSWorkspace.shared.open(url)
          }
        }
      }

      Section("CLI (opcional)") {
        Text("Após `make install`, use `finder-kit analyze ~/Downloads` no terminal.")
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .formStyle(.grouped)
    .frame(width: 480, height: 280)
    .padding()
  }
}
