/// How far along Apple's release process a runtime is.
public enum ReleaseStage: Equatable, Sendable {
    /// A beta, with its number when Apple gives one (the first beta usually has none).
    case beta(Int?)
    case releaseCandidate
    case release

    /// Reads the stage from an index entry's name, such as `iOS 27.2 beta 4 Simulator Runtime`.
    init(name: String) {
        if let match = name.firstMatch(of: /\sbeta(?:\s(\d+))?\b/) {
            self = .beta(match.1.flatMap { Int($0) })
        } else if name.contains("Release Candidate") {
            self = .releaseCandidate
        } else {
            self = .release
        }
    }

    /// A short label such as `beta 4` or `RC`, or `nil` for a release.
    public var label: String? {
        switch self {
        case let .beta(number): number.map { "beta \($0)" } ?? "beta"
        case .releaseCandidate: "RC"
        case .release: nil
        }
    }
}
