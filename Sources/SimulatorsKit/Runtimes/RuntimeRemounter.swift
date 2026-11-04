/// Brings back a runtime that `simctl` unregistered but whose files it kept (see
/// ``RuntimeAssetKept``), so it can be deleted again.
public struct RuntimeRemounter: Sendable {
    private let runner: any CommandRunner
    private let installedRuntimes: InstalledRuntimeService
    private let pollInterval: Duration
    private let timeout: Duration
    private let sleep: @Sendable (Duration) async throws -> Void

    /// - Parameters:
    ///   - pollInterval: How long to wait between looking for the runtime.
    ///   - timeout: How long to keep looking before giving up.
    ///   - sleep: Waits for the given duration; injectable so tests don't wait.
    public init(
        runner: any CommandRunner = ProcessCommandRunner(),
        pollInterval: Duration = .seconds(5),
        timeout: Duration = .seconds(120),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.runner = runner
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.pollInterval = pollInterval
        self.timeout = timeout
        self.sleep = sleep
    }

    /// Runs `simctl runtime scan-and-mount` and waits until `runtime` is registered and ready again.
    /// CoreSimulator does this in the background, so it can take a while.
    ///
    /// - Returns: The runtime as registered now (its UUID may have changed), or `nil` if it isn't
    ///   back within the timeout.
    public func remount(_ runtime: InstalledRuntime) async throws -> InstalledRuntime? {
        _ = try await runner.run("/usr/bin/xcrun", ["simctl", "runtime", "scan-and-mount"])

        var waited = Duration.zero
        while true {
            let back = try await installedRuntimes.installedRuntimes().first {
                $0.runtimeIdentifier == runtime.runtimeIdentifier && $0.build == runtime.build && $0.isReady
            }
            if let back { return back }
            guard waited < timeout else { return nil }
            try await sleep(pollInterval)
            waited += pollInterval
        }
    }
}
