import Foundation
import SimulatorsKit

/// Shows a numbered table and asks which rows to use, until the answer is valid.
struct NumberedPicker {
    let terminal: any Terminal

    /// - Parameters:
    ///   - items: The rows of `table`, in the same order as its numbers.
    ///   - table: The rendered, numbered table.
    ///   - prompt: The question, without the input hint.
    ///   - emptyMeansAll: Whether an empty answer picks every item instead of none. The prompt
    ///     says so.
    /// - Returns: The picked items. None when input ends, or when the answer is empty and
    ///   `emptyMeansAll` is false.
    func pick<Item>(_ items: [Item], table: String, prompt: String, emptyMeansAll: Bool = false) -> [Item] {
        terminal.write(table + "\n")
        let selection = NumberedSelection(count: items.count)
        let hint = emptyMeansAll ? "(e.g. 1 3, 2-4, all) [all]" : "(e.g. 1 3, 2-4, all)"
        while let input = terminal.readLine(prompt: "\(prompt) \(hint): ") {
            if emptyMeansAll && input.trimmingCharacters(in: .whitespaces).isEmpty {
                return items
            }
            do {
                return try selection.indices(from: input).map { items[$0] }
            } catch {
                terminal.write(error.localizedDescription)
            }
        }
        return []
    }
}
