import Foundation

/// Reads the simulator runtimes installed on this Mac.
public struct InstalledRuntimeService: Sendable {
    private let runner: any CommandRunner

    public init(runner: any CommandRunner = ProcessCommandRunner()) {
        self.runner = runner
    }

    /// Installed runtimes in listing order (see ``InstalledRuntime/isOrderedBefore(_:_:)``).
    ///
    /// Skips entries that lack required fields: `simctl` lists a runtime it's still registering
    /// (for example after `scan-and-mount`) before it knows everything about it.
    public func installedRuntimes() async throws -> [InstalledRuntime] {
        let output = try await runner.run("/usr/bin/xcrun", ["simctl", "runtime", "list", "-j"])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([String: SkippingInvalid].self, from: output)

        return entries.values.compactMap(\.runtime).sorted(by: InstalledRuntime.isOrderedBefore)
    }
}

/// A runtime entry, or `nil` when it can't be decoded.
private struct SkippingInvalid: Decodable {
    let runtime: InstalledRuntime?

    init(from decoder: any Decoder) throws {
        runtime = try? InstalledRuntime(from: decoder)
    }
}
