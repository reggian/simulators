import Foundation

/// Reads the simulator runtimes installed on this Mac.
public struct InstalledRuntimeService: Sendable {
    private let runner: any CommandRunner

    public init(runner: any CommandRunner = ProcessCommandRunner()) {
        self.runner = runner
    }

    /// Installed runtimes in listing order (see ``InstalledRuntime/isOrderedBefore(_:_:)``).
    public func installedRuntimes() async throws -> [InstalledRuntime] {
        let output = try await runner.run("/usr/bin/xcrun", ["simctl", "runtime", "list", "-j"])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let runtimesByIdentifier = try decoder.decode([String: InstalledRuntime].self, from: output)

        return runtimesByIdentifier.values.sorted(by: InstalledRuntime.isOrderedBefore)
    }
}
