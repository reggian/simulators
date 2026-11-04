/// Decides which installed runtimes prune offers to remove.
public struct PruneRule: Sendable {
    public init() {}

    /// A runtime is a candidate when a newer build of it is installed: same runtime identifier, so
    /// the same platform, version and device. Different versions never supersede each other, and
    /// device-specific runtimes only compete with each other.
    ///
    /// "Newer" goes by release stage first, then build number: Apple's build numbers don't sort
    /// across stages (iOS 27.2 RC `24B114` is newer than beta 4 `24B5110a`). Stages come from
    /// Apple's index; a group with a build the index doesn't know is left undecided.
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

        let ordered = candidates.sorted { InstalledRuntime.isOrderedBefore($0.runtime, $1.runtime) }
        return PrunePlan(
            candidates: ordered.filter { usage.xcodes(using: $0.runtime).isEmpty },
            keptInUse: ordered.filter { !usage.xcodes(using: $0.runtime).isEmpty },
            undecided: undecided.sorted { InstalledRuntime.isOrderedBefore($0[0], $1[0]) }
        )
    }

    private static func isOlder(_ lhs: (InstalledRuntime, ReleaseStage), than rhs: (InstalledRuntime, ReleaseStage)) -> Bool {
        if lhs.1 != rhs.1 { return lhs.1.precedes(rhs.1) }
        return lhs.0.build.numericallyPrecedes(rhs.0.build) ?? false
    }
}
