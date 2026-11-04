extension ReleaseStage {
    /// Whether this stage comes before `other` in Apple's release process: betas by number, then
    /// the release candidate, then the release. A beta without a number is the first beta.
    func precedes(_ other: ReleaseStage) -> Bool {
        rank.0 != other.rank.0 ? rank.0 < other.rank.0 : rank.1 < other.rank.1
    }

    private var rank: (Int, Int) {
        switch self {
        case let .beta(number): (0, number ?? 1)
        case .releaseCandidate: (1, 0)
        case .release: (2, 0)
        }
    }
}
