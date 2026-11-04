extension Array where Element == AvailableRuntime {
    /// The builds worth offering by default: per platform and version, the release builds, or the
    /// newest beta or release candidate when there's no release yet. Keeps the order.
    ///
    /// A version can have several release builds, such as a device-specific one next to the
    /// regular one; both stay.
    public func current() -> [AvailableRuntime] {
        let byVersion = Dictionary(grouping: self) { VersionKey(platform: $0.platform, version: $0.version) }
        let kept = byVersion.values.flatMap { builds in
            let releases = builds.filter { $0.stage == .release }
            if !releases.isEmpty { return releases }
            return builds.max { $0.build.numericallyPrecedes($1.build) ?? false }.map { [$0] } ?? []
        }
        let keptBuilds = Set(kept.map { BuildKey(platform: $0.platform, build: $0.build) })
        return filter { keptBuilds.contains(BuildKey(platform: $0.platform, build: $0.build)) }
    }
}

private struct VersionKey: Hashable {
    let platform: SimulatorPlatform
    let version: String
}

private struct BuildKey: Hashable {
    let platform: SimulatorPlatform
    let build: String
}
