import Foundation
import SimulatorsKit

/// A table of installed runtimes followed by a total. Numbered when the user picks from it; names
/// carry beta and RC labels when `stages` knows them; with a Used by column when `usage` is given.
struct RuntimeTable {
    let runtimes: [InstalledRuntime]
    var stages: ReleaseStageLookup = .empty
    var usage: RuntimeUsage?
    var numbered = false
    var now: Date = .now
    var calendar: Calendar = .current
    var locale: Locale = .current

    func render() -> String {
        let lastUsed = LastUsedDescription(now: now, calendar: calendar)
        var header = ["Runtime", "Build", "Arch", "Size", "Last used"]
        if usage != nil { header.append("Used by") }

        let rows = runtimes.map { runtime in
            var row = [
                runtime.name(stage: stages.stage(of: runtime)),
                runtime.build,
                architecture(of: runtime),
                runtime.sizeBytes.map { $0.fileSize(locale: locale) } ?? "-",
                lastUsed.describe(runtime.lastUsedAt),
            ]
            if let usage { row.append(usage.xcodes(using: runtime).map(\.name).joined(separator: ", ")) }
            return row
        }
        let table = numbered
            ? TextTable(header: ["#"] + header, rows: rows.enumerated().map { ["\($0.offset + 1)"] + $0.element })
            : TextTable(header: header, rows: rows)
        return table.render() + "\n\n" + total
    }

    private var total: String {
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return "\(count), \(Int64.totalSize(of: runtimes.map(\.sizeBytes)).fileSize(locale: locale))"
    }

    private func architecture(of runtime: InstalledRuntime) -> String {
        if Set(runtime.architectures).isSuperset(of: ["arm64", "x86_64"]) {
            return "universal"
        }
        return runtime.architectures.isEmpty ? "-" : runtime.architectures.joined(separator: ", ")
    }
}
