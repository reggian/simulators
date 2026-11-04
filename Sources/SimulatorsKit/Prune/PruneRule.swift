import Foundation

/// Decides which installed runtimes prune offers to remove.
public struct PruneRule: Sendable {
    /// Also offer runtimes not used for this many days; `nil` offers superseded builds only.
    public let unusedForDays: Int?
    public let now: Date

    public init(unusedForDays: Int? = nil, now: Date = .now) {
        self.unusedForDays = unusedForDays
        self.now = now
    }

    /// A runtime is a candidate when a newer build of it is installed: same runtime identifier, so
    /// the same platform, version and device. Different versions never supersede each other, and
    /// device-specific runtimes only compete with each other.
    ///
    /// "Newer" goes by release stage first, then build number: Apple's build numbers don't sort
    /// across stages (iOS 27.2 RC `24B114` is newer than beta 4 `24B5110a`). Stages come from
    /// Apple's index; a group with a build the index doesn't know is left undecided.
    ///
    /// With ``unusedForDays``, a runtime last used longer ago is a candidate too. A runtime without
    /// a last-used date never is: `simctl` doesn't record one for every runtime, so a missing date
    /// says nothing about age.
    ///
    /// Runtimes `simctl` can't delete are never candidates, and runtimes an installed Xcode uses
    /// are kept.
    public func plan(for installed: [InstalledRuntime], stages: ReleaseStageLookup, usage: RuntimeUsage) -> PrunePlan {
        var candidates: [PruneCandidate] = []
        var undecided: [[InstalledRuntime]] = []

        let groups = Dictionary(grouping: installed, by: \.runtimeIdentifier).values.filter { $0.count > 1 }
        for group in groups {
            let ranked = group.compactMap { runtime in stages.stage(of: runtime).map { (runtime, $0) } }
            guard ranked.count == group.count else {
                undecided.append(group.sorted(by: InstalledRuntime.isOrderedBefore))
                continue
            }
            let newest = ranked.max { Self.isOlder($0, than: $1) }!.0
            candidates += group
                .filter { $0 != newest && $0.isDeletable }
                .map { PruneCandidate(runtime: $0, reason: .superseded(by: newest)) }
        }

        candidates += unused(in: installed, except: Set(candidates.map(\.runtime.identifier)))

        let ordered = candidates.sorted { InstalledRuntime.isOrderedBefore($0.runtime, $1.runtime) }
        return PrunePlan(
            candidates: ordered.filter { usage.xcodes(using: $0.runtime).isEmpty },
            keptInUse: ordered.filter { !usage.xcodes(using: $0.runtime).isEmpty },
            undecided: undecided.sorted { InstalledRuntime.isOrderedBefore($0[0], $1[0]) }
        )
    }

    private func unused(in installed: [InstalledRuntime], except excluded: Set<String>) -> [PruneCandidate] {
        guard let unusedForDays else { return [] }
        let cutoff = now.addingTimeInterval(-Double(unusedForDays) * 24 * 60 * 60)
        return installed.compactMap { runtime in
            guard runtime.isDeletable, !excluded.contains(runtime.identifier),
                  let lastUsedAt = runtime.lastUsedAt, lastUsedAt < cutoff
            else { return nil }
            return PruneCandidate(runtime: runtime, reason: .unused(lastUsedAt: lastUsedAt))
        }
    }

    private static func isOlder(_ lhs: (InstalledRuntime, ReleaseStage), than rhs: (InstalledRuntime, ReleaseStage)) -> Bool {
        if lhs.1 != rhs.1 { return lhs.1.precedes(rhs.1) }
        return lhs.0.build.numericallyPrecedes(rhs.0.build) ?? false
    }
}
