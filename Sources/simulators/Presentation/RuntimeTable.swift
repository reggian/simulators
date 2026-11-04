import Foundation
import SimulatorsKit

/// A table of installed runtimes followed by a total. Numbered when the user picks from it; names
/// carry beta and RC labels when `stages` knows them; with a Used by column when `usage` is given.
struct RuntimeTable {
    let runtimes: [InstalledRuntime]
    var stages: ReleaseStageLookup = .empty
    var usage: RuntimeUsage?
    var numbered = false
    var styler: Styler = .plain
    var now: Date = .now
    var calendar: Calendar = .current
    var locale: Locale = .current

    private var describer: RuntimeDescriber {
        RuntimeDescriber(stages: stages, usage: usage ?? .empty)
    }

    func render() -> String {
        let lastUsed = LastUsedDescription(now: now, calendar: calendar)
        var header = ["Runtime", "Build", "Arch", "Size", "Last used"]
        if usage != nil { header.append("Used by") }

        let rows = runtimes.map { runtime in
            var row = [
                TextTable.Cell(describer.name(of: runtime), describer.nameStyle(of: runtime)),
                TextTable.Cell(runtime.build),
                TextTable.Cell(architecture(of: runtime)),
                TextTable.Cell(runtime.sizeBytes.map { $0.fileSize(locale: locale) }),
                TextTable.Cell(runtime.lastUsedAt.map { lastUsed.describe($0) }),
            ]
            if let usage { row.append(TextTable.Cell(usage.xcodes(using: runtime).map(\.name).joined(separator: ", "))) }
            return row
        }
        let table = numbered
            ? TextTable.numbered(header: header, rows: rows, styler: styler)
            : TextTable(header: header, rows: rows, styler: styler)
        return table.render() + "\n\n" + styler(total, .dim)
    }

    private var total: String {
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return "\(count), \(Int64.totalSize(of: runtimes.map(\.sizeBytes)).fileSize(locale: locale))"
    }

    private func architecture(of runtime: InstalledRuntime) -> String? {
        if Set(runtime.architectures).isSuperset(of: ["arm64", "x86_64"]) {
            return "universal"
        }
        return runtime.architectures.isEmpty ? nil : runtime.architectures.joined(separator: ", ")
    }
}
