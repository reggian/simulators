import Foundation

/// Where commands talk to the user. Tests replace it with scripted answers.
protocol Terminal: Sendable {
    /// Whether someone can answer prompts. False when stdin is a pipe or file, for example in CI.
    var isInteractive: Bool { get }

    /// How to style output; plain when it isn't going to a terminal.
    var styler: Styler { get }

    func write(_ text: String)

    /// Shows `prompt` and returns the typed line, or `nil` at end of input.
    func readLine(prompt: String) -> String?
}

/// The process's own stdin and stdout.
struct StandardTerminal: Terminal {
    var isInteractive: Bool {
        isatty(STDIN_FILENO) != 0
    }

    var styler: Styler {
        .standardOutput()
    }

    func write(_ text: String) {
        print(text)
    }

    func readLine(prompt: String) -> String? {
        print(prompt, terminator: "")
        fflush(stdout)
        return Swift.readLine()
    }
}
