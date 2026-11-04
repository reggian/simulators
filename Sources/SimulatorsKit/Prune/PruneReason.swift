import Foundation

/// Why a runtime is a prune candidate.
public enum PruneReason: Equatable, Sendable {
    /// A newer build of the same runtime (same platform, version and device) is installed.
    case superseded(by: InstalledRuntime)
}
