import Foundation

enum InstallError: LocalizedError, Equatable {
    case runtimeArgumentRequired
    case confirmationRequired
    case noMatch(String)
    case ambiguous(String, matches: [String])
    case variantUnavailable(String, requested: String, offered: [String])
    case incomplete(failed: [String])

    var errorDescription: String? {
        switch self {
        case .runtimeArgumentRequired:
            "There's no terminal to ask which runtimes to install. Pass them as arguments, "
                + "for example `simulators install iOS 27.2`."
        case .confirmationRequired:
            "There's no terminal to confirm the install. Pass --yes to skip the confirmation."
        case let .noMatch(query):
            "Apple offers no runtime matching \"\(query)\". Run `simulators list --available` to see them."
        case let .ambiguous(query, matches):
            "\"\(query)\" matches several runtimes: \(matches.joined(separator: ", ")). "
                + "Pass a build number to pick one."
        case let .variantUnavailable(name, requested, offered):
            "\(name) isn't available as \(requested), only as \(offered.joined(separator: " and "))."
        case let .incomplete(failed):
            "Couldn't install \(failed.joined(separator: ", "))."
        }
    }
}
