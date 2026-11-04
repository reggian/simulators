import SimulatorsKit

/// Shows a numbered table and asks which rows to use, until the answer is valid.
struct NumberedPicker {
    let terminal: any Terminal

    /// - Parameters:
    ///   - items: The rows of `table`, in the same order as its numbers.
    ///   - table: The rendered, numbered table.
    ///   - prompt: The question, without the input hint.
    /// - Returns: The picked items, or none when the answer is empty or input ends.
    func pick<Item>(_ items: [Item], table: String, prompt: String) -> [Item] {
        terminal.write(table + "\n")
        let selection = NumberedSelection(count: items.count)
        while let input = terminal.readLine(prompt: "\(prompt) (e.g. 1 3, 2-4, all): ") {
            do {
                return try selection.indices(from: input).map { items[$0] }
            } catch {
                terminal.write(error.localizedDescription)
            }
        }
        return []
    }
}
