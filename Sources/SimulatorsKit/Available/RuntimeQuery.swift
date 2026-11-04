/// A runtime the user asked to install: a build, or a platform with an optional version.
public enum RuntimeQuery: Equatable, Sendable {
    /// An exact build, such as `24B8117`.
    case build(String)
    /// A platform's newest release (`iOS`), or a version of it (`iOS 27.2`).
    case platform(SimulatorPlatform, version: String?)

    /// Reads queries from command-line arguments. `iOS 27.2` works quoted or as two arguments;
    /// a word that isn't a platform is a build.
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
            queries.append(.platform(platform, version: version))
        }
        return queries
    }

    /// The query as the user would type it, for messages.
    public var description: String {
        switch self {
        case let .build(build): build
        case let .platform(platform, version): version.map { "\(platform.name) \($0)" } ?? platform.name
        }
    }
}
