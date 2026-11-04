extension AvailableRuntime {
    /// Listing order, matching installed runtimes: platform, then version, then build (all
    /// ascending).
    public static func isOrderedBefore(_ lhs: AvailableRuntime, _ rhs: AvailableRuntime) -> Bool {
        if lhs.platform.sortOrder != rhs.platform.sortOrder {
            return lhs.platform.sortOrder < rhs.platform.sortOrder
        }
        if lhs.platform.name != rhs.platform.name {
            return lhs.platform.name < rhs.platform.name
        }
        if let order = lhs.version.numericallyPrecedes(rhs.version) {
            return order
        }
        return lhs.build.numericallyPrecedes(rhs.build) ?? false
    }
}
