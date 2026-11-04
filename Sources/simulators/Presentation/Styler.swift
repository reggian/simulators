import Foundation

/// Applies styles with ANSI escape codes, or leaves text plain.
struct Styler: Sendable {
    let isEnabled: Bool

    /// Never styles: for pipes, files and tests.
    static let plain = Styler(isEnabled: false)

    /// `text` in `style`, or unchanged when styling is off, `style` is `nil` or `text` is empty.
    func callAsFunction(_ text: String, _ style: Style?) -> String {
        guard isEnabled, let style, !text.isEmpty else { return text }
        return "\u{1B}[\(style.code)m\(text)\u{1B}[0m"
    }

    /// Styles standard output only when it's a terminal, `NO_COLOR` isn't set (no-color.org) and
    /// `TERM` isn't `dumb`.
    static func standardOutput(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isTerminal: Bool = isatty(STDOUT_FILENO) != 0
    ) -> Styler {
        let noColor = !(environment["NO_COLOR"] ?? "").isEmpty
        return Styler(isEnabled: isTerminal && !noColor && environment["TERM"] != "dumb")
    }
}
