import Foundation
import SimulatorsKit

/// A table of installed runtimes followed by a total. Numbered when the user picks from it; names
/// carry beta and RC labels when `stages` knows them.
struct RuntimeTable {
    let runtimes: [InstalledRuntime]
    var stages: ReleaseStageLookup = .empty
    var numbered = false
    var now: Date = .now
    var calendar: Calendar = .current
    var locale: Locale = .current

    func render() -> String {
        let lastUsed = LastUsedDescription(now: now, calendar: calendar)
        let header = ["Runtime", "Build", "Arch", "Size", "Last used"]
        let rows = runtimes.map { runtime in
            [
                runtime.name(stage: stages.stage(of: runtime)),
                runtime.build,
                architecture(of: runtime),
                runtime.sizeBytes.map { $0.fileSize(locale: locale) } ?? "-",
                lastUsed.describe(runtime.lastUsedAt),
            ]
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
