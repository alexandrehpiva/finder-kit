import Foundation

/// Acesso a URLs com escopo de segurança (extensões sandboxed do Finder).
public enum SecurityScopedAccess {
  /// Inicia acesso ao escopo antes de `body` e encerra no `defer`.
  public static func withAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
    let started = url.startAccessingSecurityScopedResource()
    defer {
      if started {
        url.stopAccessingSecurityScopedResource()
      }
    }
    return try body()
  }
}
