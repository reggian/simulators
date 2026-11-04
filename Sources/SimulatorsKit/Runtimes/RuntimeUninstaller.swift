import Foundation

/// Deletes installed simulator runtimes with `simctl`.
public struct RuntimeUninstaller: Sendable {
    private let runner: any CommandRunner
    private let fileExists: @Sendable (String) -> Bool
    private let pollInterval: Duration
    private let removalTimeout: Duration
    private let sleep: @Sendable (Duration) async throws -> Void

    /// - Parameters:
    ///   - fileExists: Whether a file or folder exists at a path; injectable for tests.
    ///   - pollInterval: How long to wait between checks for the runtime's files.
    ///   - removalTimeout: How long to give the files to disappear after a successful delete.
    ///   - sleep: Waits for the given duration; injectable so tests don't wait.
    public init(
        runner: any CommandRunner = ProcessCommandRunner(),
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) },
        pollInterval: Duration = .seconds(1),
        removalTimeout: Duration = .seconds(30),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.runner = runner
        self.fileExists = fileExists
        self.pollInterval = pollInterval
        self.removalTimeout = removalTimeout
        self.sleep = sleep
    }

    /// Deletes `runtime` by its UUID, then checks that its files are gone. `simctl` shuts down any
    /// simulators booted on it first.
    ///
    /// - Throws: ``RuntimeAssetKept`` when the runtime was unregistered but its files stayed on
    ///   disk, whether `simctl` reported it or not; ``CommandFailure`` for any other failure.
    public func uninstall(_ runtime: InstalledRuntime) async throws {
        do {
            _ = try await runner.run("/usr/bin/xcrun", ["simctl", "runtime", "delete", runtime.identifier])
        } catch let failure as CommandFailure {
            if let kept = RuntimeAssetKept(failure) { throw kept }
            throw failure
        }

        if let path = runtime.path, try await !filesDisappear(at: path) {
            throw RuntimeAssetKept(assetPath: path)
        }
    }

    /// Waits for `path` to disappear, in case `simctl` removes the files after it exits.
    private func filesDisappear(at path: String) async throws -> Bool {
        var waited = Duration.zero
        while fileExists(path) {
            guard waited < removalTimeout else { return false }
            try await sleep(pollInterval)
            waited += pollInterval
        }
        return true
    }
}
