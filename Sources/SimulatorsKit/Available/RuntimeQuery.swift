/// A runtime the user asked to install: a build, or a platform with an optional version.
public enum RuntimeQuery: Equatable, Sendable {
    /// An exact build, such as `24B8117`.
    case build(String)
    /// A platform's newest release (`iOS`), or a version of it (`iOS 27.2`).
    case platform(SimulatorPlatform, version: String?)
    /// A beta or release candidate of a version: `iOS 27.3 beta`, `iOS 27.2 beta 4`, `iOS 27.2 RC`.
    case stage(SimulatorPlatform, version: String, ReleaseStage)

    /// Reads queries from command-line arguments. `iOS 27.2 beta 4` works quoted or as separate
    /// arguments; a word that isn't a platform is a build.
    public static func parse(_ arguments: [String]) -> [RuntimeQuery] {
        var words = arguments.flatMap { $0.split(whereSeparator: \.isWhitespace).map(String.init) }[...]
        var queries: [RuntimeQuery] = []
        while let word = words.popFirst() {
            guard let platform = SimulatorPlatform.named(word) else {
                queries.append(.build(word))
                continue
            }
            let version = words.first.flatMap { $0.wholeMatch(of: /\d+(\.\d+)*/) != nil ? $0 : nil }
            if version != nil { words.removeFirst() }
            if let version, let stage = Self.stage(from: &words) {
                queries.append(.stage(platform, version: version, stage))
            } else {
                queries.append(.platform(platform, version: version))
            }
        }
        return queries
    }

    /// Takes `beta`, `beta 4` or `RC` (any case) off the front of `words`, if there.
    private static func stage(from words: inout ArraySlice<String>) -> ReleaseStage? {
        switch words.first?.lowercased() {
        case "beta":
            words.removeFirst()
            guard let number = words.first.flatMap({ Int($0) }) else { return .beta(nil) }
            words.removeFirst()
            return .beta(number)
        case "rc":
            words.removeFirst()
            return .releaseCandidate
        default:
            return nil
        }
    }

    /// The query as the user would type it, for messages.
    public var description: String {
        switch self {
        case let .build(build): build
        case let .platform(platform, version): version.map { "\(platform.name) \($0)" } ?? platform.name
        case let .stage(platform, version, stage): [platform.name, version, stage.label].compactMap { $0 }.joined(separator: " ")
        }
    }
}
