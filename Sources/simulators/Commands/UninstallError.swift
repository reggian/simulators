import Foundation

enum UninstallError: LocalizedError, Equatable {
    case runtimeArgumentRequired
    case confirmationRequired
    case noMatch(String)
    case ambiguous(String, matches: [String])
    case notDeletable(String)
    /// `freed` is `nil` when nothing was freed.
    case incomplete(failed: [String], freed: String?)

    var errorDescription: String? {
        switch self {
        case .runtimeArgumentRequired:
            "There's no terminal to ask which runtimes to uninstall. Pass them as arguments, "
                + "for example `simulators uninstall 24B8117`."
        case .confirmationRequired:
            "There's no terminal to confirm the uninstall. Pass --yes to skip the confirmation."
        case let .noMatch(query):
            "No installed runtime matches \"\(query)\". Run `simulators list` to see them."
        case let .ambiguous(query, matches):
            "\"\(query)\" matches several runtimes: \(matches.joined(separator: ", ")). "
                + "Pass a build number to pick one."
        case let .notDeletable(name):
            "\(name) can't be uninstalled: simctl marks it as not deletable, "
                + "which usually means it's bundled with an Xcode."
        case let .incomplete(failed, freed):
            (freed.map { "Freed \($0), but couldn't" } ?? "Couldn't")
                + " fully uninstall \(failed.joined(separator: ", "))."
        }
    }
}
