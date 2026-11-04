import Foundation
import SimulatorsKit

/// Answers `simctl runtime list -j` with canned JSON, fails a delete once if told to, accepts
/// every other command with empty output, and records everything it was asked to run.
final class RecordingCommandRunner: CommandRunner, @unchecked Sendable {
    static let listCommand = ["/usr/bin/xcrun", "simctl", "runtime", "list", "-j"]
    private static let deleteCommand = ["/usr/bin/xcrun", "simctl", "runtime", "delete"]

    private let runtimeListJSON: String
    private var deleteFailures: [String: any Error]
    private let lock = NSLock()
    private var recorded: [[String]] = []

    /// - Parameter deleteFailures: Errors to throw the first time the runtime with that UUID is deleted.
    init(runtimeListJSON: String, deleteFailures: [String: any Error] = [:]) {
        self.runtimeListJSON = runtimeListJSON
        self.deleteFailures = deleteFailures
    }

    var commands: [[String]] {
        lock.withLock { recorded }
    }

    /// The UUIDs passed to `simctl runtime delete`, in order, including failed ones.
    var deletedIdentifiers: [String] {
        commands.filter { $0.starts(with: Self.deleteCommand) }.compactMap(\.last)
    }

    func run(_ executable: String, _ arguments: [String]) async throws -> Data {
        let command = [executable] + arguments
        let failure: (any Error)? = lock.withLock {
            recorded.append(command)
            guard command.starts(with: Self.deleteCommand), let identifier = command.last else { return nil }
            return deleteFailures.removeValue(forKey: identifier)
        }
        if let failure { throw failure }
        return command == Self.listCommand ? Data(runtimeListJSON.utf8) : Data()
    }
}
