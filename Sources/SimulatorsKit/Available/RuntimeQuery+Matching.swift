extension RuntimeQuery {
    /// The runtimes in `available` this query asks for. Several means the user has to choose.
    ///
    /// - A build matches that build.
    /// - A platform and version match that version's release builds, or its newest beta when it
    ///   has no release yet.
    /// - A platform alone matches its newest release (or newest beta, if it has no release at all).
    public func matches(in available: [AvailableRuntime]) -> [AvailableRuntime] {
        switch self {
        case let .build(build):
            return available.filter { $0.build.lowercased() == build.lowercased() }
        case let .platform(platform, version?):
            return available.current().filter { $0.platform == platform && $0.version == version }
        case let .platform(platform, nil):
            let candidates = available.current().filter { $0.platform == platform }
            let releases = candidates.filter { $0.stage == .release }
            let pool = releases.isEmpty ? candidates : releases
            guard let newest = pool.max(by: { $0.version.numericallyPrecedes($1.version) ?? false }) else { return [] }
            return pool.filter { $0.version == newest.version }
        }
    }
}
