import Testing
@testable import simulators

@Suite("Numbered picker")
struct NumberedPickerTests {
    @Test("An empty answer picks nothing, or everything when that's the default", arguments: [
        (false, [String]()),
        (true, ["a", "b", "c"]),
    ])
    func emptyAnswer(emptyMeansAll: Bool, expected: [String]) {
        let terminal = ScriptedTerminal(answers: [" "])

        let picked = NumberedPicker(terminal: terminal).pick(["a", "b", "c"], table: "", prompt: "Pick", emptyMeansAll: emptyMeansAll)

        #expect(picked == expected)
        #expect(terminal.output.contains(emptyMeansAll ? "Pick (e.g. 1 3, 2-4, all) [all]: " : "Pick (e.g. 1 3, 2-4, all): "))
    }
}
