import Foundation
import SimulatorsKit

/// The table of installed runtimes shown by `simulators list`, followed by a total.
struct RuntimeTable {
    let runtimes: [InstalledRuntime]
    var now: Date = .now
    var calendar: Calendar = .current
    var locale: Locale = .current

    func render() -> String {
        let lastUsed = LastUsedDescription(now: now, calendar: calendar)
        let table = TextTable(
            header: ["Runtime", "Build", "Arch", "Size", "Last used"],
            rows: runtimes.map { runtime in
                [
                    runtime.name,
                    runtime.build,
                    architecture(of: runtime),
                    runtime.sizeBytes.map(formattedSize) ?? "-",
                    lastUsed.describe(runtime.lastUsedAt),
                ]
            }
        )
        return table.render() + "\n\n" + total
    }

    private var total: String {
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        let bytes = runtimes.compactMap(\.sizeBytes).reduce(0, +)
        return "\(count), \(formattedSize(bytes))"
    }

    private func architecture(of runtime: InstalledRuntime) -> String {
        if Set(runtime.architectures).isSuperset(of: ["arm64", "x86_64"]) {
            return "universal"
        }
        return runtime.architectures.isEmpty ? "-" : runtime.architectures.joined(separator: ", ")
    }

    private func formattedSize(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file).locale(locale))
    }
}
