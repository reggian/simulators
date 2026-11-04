import Foundation
import SimulatorsKit

/// Returns canned output, or fails with a canned error, and records the commands it was asked to run.
final class StubCommandRunner: CommandRunner, @unchecked Sendable {
    private let result: Result<Data, any Error>
    private let lock = NSLock()
    private var recorded: [[String]] = []

    init(output: Data) {
        self.result = .success(output)
    }

    init(failure: any Error) {
        self.result = .failure(failure)
    }

    var commands: [[String]] {
        lock.withLock { recorded }
    }

    func run(_ executable: String, _ arguments: [String]) async throws -> Data {
        lock.withLock { recorded.append([executable] + arguments) }
        return try result.get()
    }
}
