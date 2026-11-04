import Foundation

enum PruneError: LocalizedError, Equatable {
    case selectionRequired
    case xcodesUnreadable([String])

    var errorDescription: String? {
        switch self {
        case .selectionRequired:
            "There's no terminal to pick runtimes to prune. Pass --yes to prune all candidates, "
                + "or --dry-run to see them."
        case let .xcodesUnreadable(names):
            "Couldn't ask \(names.joined(separator: ", ")) which runtimes it uses, so prune can't tell "
                + "what's safe to remove. Nothing was uninstalled."
        }
    }
}
