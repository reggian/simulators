import Foundation
import SimulatorsKit

/// Answers `simctl runtime list -j` and other commands with canned output, fails a delete once or an
/// attached command if told to, answers anything else with empty output, and records everything it
/// was asked to run.
final class RecordingCommandRunner: CommandRunner, @unchecked Sendable {
    static let listCommand = ["/usr/bin/xcrun", "simctl", "runtime", "list", "-j"]
    private static let deleteCommand = ["/usr/bin/xcrun", "simctl", "runtime", "delete"]

    private let runtimeListJSON: String
    private var deleteFailures: [String: any Error]
    private let attachedFailures: [String: any Error]
    private let outputs: [[String]: String]
    private let lock = NSLock()
    private var recorded: [[String]] = []
    private var recordedAttached: [[String]] = []

    /// - Parameters:
    ///   - deleteFailures: Errors to throw the first time the runtime with that UUID is deleted.
    ///   - attachedFailures: Errors to throw for attached commands with that argument.
    ///   - outputs: Output for other commands.
    init(
        runtimeListJSON: String = "{}",
        deleteFailures: [String: any Error] = [:],
        attachedFailures: [String: any Error] = [:],
        outputs: [[String]: String] = [:]
    ) {
        self.runtimeListJSON = runtimeListJSON
        self.deleteFailures = deleteFailures
        self.attachedFailures = attachedFailures
        self.outputs = outputs
    }

    var commands: [[String]] {
        lock.withLock { recorded }
    }

    /// The commands run attached to the terminal, in order, including failed ones.
    var attachedCommands: [[String]] {
        lock.withLock { recordedAttached }
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
        if command == Self.listCommand { return Data(runtimeListJSON.utf8) }
        return Data((outputs[command] ?? "").utf8)
    }

    func runAttached(_ executable: String, _ arguments: [String]) async throws {
        let command = [executable] + arguments
        lock.withLock { recordedAttached.append(command) }
        if let failure = arguments.lazy.compactMap({ self.attachedFailures[$0] }).first {
            throw failure
        }
    }
}
