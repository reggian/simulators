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
        if let order = lhs.version.numericallyPrecedes(rhs.version) {
            return order
        }
        if (lhs.variant == nil) != (rhs.variant == nil) {
            return lhs.variant == nil
        }
        if let order = lhs.build.numericallyPrecedes(rhs.build) {
            return order
        }
        return lhs.identifier < rhs.identifier
    }
}
