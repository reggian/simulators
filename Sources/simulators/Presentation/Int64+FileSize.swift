import Foundation

extension Int64 {
    /// A byte count as a file size, for example `7.35 GB`.
    func fileSize(locale: Locale) -> String {
        formatted(.byteCount(style: .file).locale(locale))
    }

    /// The sum of `sizes`, skipping unknown ones.
    static func totalSize(of sizes: [Int64?]) -> Int64 {
        sizes.compactMap { $0 }.reduce(0, +)
    }
}
