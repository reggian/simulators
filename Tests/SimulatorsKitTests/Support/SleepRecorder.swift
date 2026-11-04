import Foundation

/// Records requested sleeps instead of waiting.
final class SleepRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [Duration] = []

    var durations: [Duration] {
        lock.withLock { recorded }
    }

    var sleep: @Sendable (Duration) async throws -> Void {
        { [self] duration in lock.withLock { recorded.append(duration) } }
    }
}
