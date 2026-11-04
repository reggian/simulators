import Foundation
import SimulatorsKit

/// A table of prune candidates with the reason for each. Numbered when the user picks from it,
/// otherwise followed by a total.
struct PruneTable {
    let candidates: [PruneCandidate]
    let describer: RuntimeDescriber
    var numbered = false
    var now: Date = .now
    var calendar: Calendar = .current
    var locale: Locale = .current

    func render() -> String {
        let lastUsed = LastUsedDescription(now: now, calendar: calendar)
        let header = ["Runtime", "Build", "Size", "Last used", "Reason"]
        let rows = candidates.map { candidate in
            [
                describer.name(of: candidate.runtime),
                candidate.runtime.build,
                candidate.runtime.sizeBytes.map { $0.fileSize(locale: locale) } ?? "-",
                lastUsed.describe(candidate.runtime.lastUsedAt),
                reason(candidate.reason),
            ]
        }
        guard !numbered else {
            return TextTable(header: ["#"] + header, rows: rows.enumerated().map { ["\($0.offset + 1)"] + $0.element })
                .render()
        }
        let runtimes = candidates.map(\.runtime)
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        let size = Int64.totalSize(of: runtimes.map(\.sizeBytes)).fileSize(locale: locale)
        return TextTable(header: header, rows: rows).render() + "\n\n\(count), \(size)"
    }

    /// For example `superseded by iOS 27.2 (24B8117)` or `not used for 7 months`.
    func reason(_ reason: PruneReason) -> String {
        switch reason {
        case let .superseded(newer):
            "superseded by \(describer.describe(newer))"
        case let .unused(lastUsedAt):
            "not used for \(age(since: lastUsedAt))"
        }
    }

    private func age(since date: Date) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if days < 60 { return "\(days) days" }
        if days < 730 { return "\(days / 30) months" }
        return "\(days / 365) years"
    }
}
