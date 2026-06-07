import Foundation

enum SemVer {
  static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
    let a = parse(lhs)
    let b = parse(rhs)
    for i in 0 ..< max(a.count, b.count) {
      let av = i < a.count ? a[i] : 0
      let bv = i < b.count ? b[i] : 0
      if av < bv { return .orderedAscending }
      if av > bv { return .orderedDescending }
    }
    return .orderedSame
  }

  private static func parse(_ version: String) -> [Int] {
    version
      .split(separator: ".", omittingEmptySubsequences: false)
      .map { Int($0) ?? 0 }
  }
}
