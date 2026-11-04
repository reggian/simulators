/// A runtime prune would remove, and why.
public struct PruneCandidate: Equatable, Sendable {
    public let runtime: InstalledRuntime
    public let reason: PruneReason

    public init(runtime: InstalledRuntime, reason: PruneReason) {
        self.runtime = runtime
        self.reason = reason
    }
}
