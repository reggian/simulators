import Foundation
@testable import simulators

/// A terminal that answers prompts from a script and records what was written.
final class ScriptedTerminal: Terminal, @unchecked Sendable {
    let isInteractive: Bool
    private let lock = NSLock()
    private var answers: [String]
    private var written: [String] = []

    init(isInteractive: Bool = true, answers: [String] = []) {
        self.isInteractive = isInteractive
        self.answers = answers
    }

    var output: String {
        lock.withLock { written.joined(separator: "\n") }
    }

    func write(_ text: String) {
        lock.withLock { written.append(text) }
    }

    func readLine(prompt: String) -> String? {
        lock.withLock {
            written.append(prompt)
            return answers.isEmpty ? nil : answers.removeFirst()
        }
    }
}
