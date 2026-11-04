/// Deletes installed simulator runtimes with `simctl`.
public struct RuntimeUninstaller: Sendable {
    private let runner: any CommandRunner

    public init(runner: any CommandRunner = ProcessCommandRunner()) {
        self.runner = runner
    }

    /// Deletes `runtime` by its UUID. `simctl` shuts down any simulators booted on it first.
    ///
    /// - Throws: ``RuntimeAssetKept`` when the runtime was unregistered but its files stayed on
    ///   disk; ``CommandFailure`` for any other failure.
    public func uninstall(_ runtime: InstalledRuntime) async throws {
        do {
            _ = try await runner.run("/usr/bin/xcrun", ["simctl", "runtime", "delete", runtime.identifier])
        } catch let failure as CommandFailure {
            if let kept = RuntimeAssetKept(failure) { throw kept }
            throw failure
        }
    }
}
