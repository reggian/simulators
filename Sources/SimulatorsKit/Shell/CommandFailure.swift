import Foundation

/// A command that exited with a non-zero status.
public struct CommandFailure: LocalizedError, Equatable, Sendable {
    public let command: [String]
    public let exitCode: Int32
    public let standardError: String

    public init(command: [String], exitCode: Int32, standardError: String) {
        self.command = command
        self.exitCode = exitCode
        self.standardError = standardError
    }

    public var errorDescription: String? {
        let details = standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = "`\(command.joined(separator: " "))` failed with exit code \(exitCode)"
        return details.isEmpty ? summary : "\(summary): \(details)"
    }
}
