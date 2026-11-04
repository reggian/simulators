import Foundation
import SimulatorsKit

/// Answers each command with its scripted outputs in turn, repeating the last one, answers
/// unscripted commands with empty output, and records everything it was asked to run.
final class SequencedCommandRunner: CommandRunner, @unchecked Sendable {
    private let lock = NSLock()
    private var outputs: [[String]: [Data]]
    private var recorded: [[String]] = []

    init(outputs: [[String]: [Data]]) {
        self.outputs = outputs
    }

    var commands: [[String]] {
        lock.withLock { recorded }
    }

    func run(_ executable: String, _ arguments: [String]) async throws -> Data {
        let command = [executable] + arguments
        return lock.withLock {
            recorded.append(command)
            guard var queue = outputs[command], let next = queue.first else { return Data() }
            if queue.count > 1 { queue.removeFirst() }
            outputs[command] = queue
            return next
        }
    }
}
