import Foundation

/// Runs an external command and returns its standard output.
///
/// Everything that shells out goes through this protocol, so tests can replace the real
/// `xcrun`, `simctl` and `xcodebuild` with canned output.
public protocol CommandRunner: Sendable {
    /// Runs `executable` with `arguments` and returns its standard output.
    ///
    /// - Throws: ``CommandFailure`` when the command exits with a non-zero status.
    func run(_ executable: String, _ arguments: [String]) async throws -> Data
}
