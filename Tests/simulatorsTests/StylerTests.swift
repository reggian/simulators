import Testing
@testable import simulators

@Suite("Styler")
struct StylerTests {
    @Test("Styles only a terminal without NO_COLOR or a dumb TERM", arguments: [
        (true, [String: String](), true),
        (false, [:], false),
        (true, ["NO_COLOR": "1"], false),
        (true, ["NO_COLOR": ""], true),
        (true, ["TERM": "dumb"], false),
    ])
    func detection(isTerminal: Bool, environment: [String: String], enabled: Bool) {
        #expect(Styler.standardOutput(environment: environment, isTerminal: isTerminal).isEnabled == enabled)
    }

    @Test("Wraps text in an escape code and a reset, leaving empty text alone")
    func styles() {
        let sut = Styler(isEnabled: true)

        #expect(sut("Runtime", .bold) == "\u{1B}[1mRuntime\u{1B}[0m")
        #expect(sut("", .dim) == "")
        #expect(Styler.plain("Runtime", .bold) == "Runtime")
    }
}
