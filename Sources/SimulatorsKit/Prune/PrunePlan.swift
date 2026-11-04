/// What prune would remove, what it keeps despite a reason to remove it, and what it can't decide.
public struct PrunePlan: Equatable, Sendable {
    /// Runtimes to offer for removal, in listing order.
    public let candidates: [PruneCandidate]
    /// Runtimes with a reason to remove them that an installed Xcode uses, so they stay.
    public let keptInUse: [PruneCandidate]
    /// Groups of builds of one runtime that can't be ranked because Apple's index doesn't list
    /// them all, so none of them is a candidate.
    public let undecided: [[InstalledRuntime]]

    public init(candidates: [PruneCandidate], keptInUse: [PruneCandidate], undecided: [[InstalledRuntime]]) {
        self.candidates = candidates
        self.keptInUse = keptInUse
        self.undecided = undecided
    }
}
