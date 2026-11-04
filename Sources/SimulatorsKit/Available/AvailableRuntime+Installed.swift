extension AvailableRuntime {
    /// Whether one of `installed` is this runtime: same platform and build.
    public func isInstalled(in installed: [InstalledRuntime]) -> Bool {
        installed.contains { $0.platform == platform && $0.build == build }
    }
}
