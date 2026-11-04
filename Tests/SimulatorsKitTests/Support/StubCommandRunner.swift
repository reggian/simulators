import Foundation
import SimulatorsKit

/// Returns canned output and records the commands it was asked to run.
final class StubCommandRunner: CommandRunner, @unchecked Sendable {
    private let output: Data
    private let lock = NSLock()
    private var recorded: [[String]] = []

    init(output: Data) {
        self.output = output
    }

    var commands: [[String]] {
        lock.withLock { recorded }
    }

    func run(_ executable: String, _ arguments: [String]) async throws -> Data {
        lock.withLock { recorded.append([executable] + arguments) }
        return output
    }
}
