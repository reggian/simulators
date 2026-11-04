import Foundation

extension InstalledRuntime {
    /// Listing order: platform, then version, then build (all ascending), regular runtimes before
    /// device-specific ones.
    public static func isOrderedBefore(_ lhs: InstalledRuntime, _ rhs: InstalledRuntime) -> Bool {
        if lhs.platform.sortOrder != rhs.platform.sortOrder {
            return lhs.platform.sortOrder < rhs.platform.sortOrder
        }
        if lhs.platform.name != rhs.platform.name {
            return lhs.platform.name < rhs.platform.name
        }
        if let order = numericOrder(lhs.version, rhs.version) {
            return order
        }
        if (lhs.variant == nil) != (rhs.variant == nil) {
            return lhs.variant == nil
        }
        if let order = numericOrder(lhs.build, rhs.build) {
            return order
        }
        return lhs.identifier < rhs.identifier
    }

    /// Compares strings with embedded numbers as numbers (`27.10` after `27.9`, `24B8117` before
    /// `24B91016s`). Returns `nil` when they're equal.
    private static func numericOrder(_ lhs: String, _ rhs: String) -> Bool? {
        switch lhs.compare(rhs, options: .numeric) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: nil
        }
    }
}
