import Testing
@testable import simulators

@Suite("Text table")
struct TextTableTests {
    @Test("Aligns columns by their plain text, then adds styles")
    func stylesWithoutShiftingColumns() {
        let sut = TextTable(
            header: ["Runtime", "Size"],
            rows: [
                [.init("iOS 27.3 beta", .yellow), .init(nil)],
                [.init("iOS 26.5"), .init("8 GB")],
            ],
            styler: Styler(isEnabled: true)
        )

        let esc = "\u{1B}"
        #expect(sut.render() == """
            \(esc)[1mRuntime\(esc)[0m        \(esc)[1mSize\(esc)[0m
            \(esc)[33miOS 27.3 beta\(esc)[0m  \(esc)[2m-\(esc)[0m
            iOS 26.5       8 GB
            """)
    }

    @Test("Ends a row at its last non-empty cell")
    func noTrailingSpaces() {
        let sut = TextTable(header: ["Runtime", "Installed"], rows: [[.init("iOS 27.2"), .init("")]])

        #expect(sut.render() == "Runtime   Installed\niOS 27.2")
    }
}
