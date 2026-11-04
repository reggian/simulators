import Testing
import SimulatorsKit

@Suite("Numbered selection")
struct NumberedSelectionTests {
    @Test("Parses numbers, ranges and all into sorted, unique indices", arguments: [
        ("2", [1]),
        ("1 3", [0, 2]),
        ("3,1", [0, 2]),
        ("2-4", [1, 2, 3]),
        ("1, 3-4 4", [0, 2, 3]),
        ("all", [0, 1, 2, 3, 4]),
        ("ALL", [0, 1, 2, 3, 4]),
        ("", []),
        ("  ", []),
    ])
    func validInput(input: String, expected: [Int]) throws {
        let sut = NumberedSelection(count: 5)

        #expect(try sut.indices(from: input) == expected)
    }

    @Test("Rejects input that doesn't describe list items", arguments: [
        ("0", NumberedSelection.Error.outOfRange(0, count: 5)),
        ("6", .outOfRange(6, count: 5)),
        ("2-9", .outOfRange(6, count: 5)),
        ("4-2", .reversedRange("4-2")),
        ("two", .invalidToken("two")),
        ("1-", .invalidToken("1-")),
        ("1-2-3", .invalidToken("1-2-3")),
        ("1 all", .invalidToken("all")),
    ])
    func invalidInput(input: String, expected: NumberedSelection.Error) {
        let sut = NumberedSelection(count: 5)

        #expect(throws: expected) { try sut.indices(from: input) }
    }
}
