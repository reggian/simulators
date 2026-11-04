/// Renders rows as left-aligned, space-separated columns with a bold header. Widths come from the
/// plain text, so styles never shift columns; rows end at their last non-empty cell, without
/// trailing spaces.
struct TextTable {
    /// One cell: its text and an optional style.
    struct Cell {
        let text: String
        let style: Style?

        init(_ text: String, _ style: Style? = nil) {
            self.text = text
            self.style = style
        }

        /// `text`, or a dimmed `-` when it's missing.
        init(_ text: String?) {
            self.init(text ?? "-", text == nil ? .dim : nil)
        }
    }

    let header: [String]
    let rows: [[Cell]]
    var styler: Styler = .plain

    private let separator = "  "

    func render() -> String {
        let allRows = [header.map { Cell($0, .bold) }] + rows
        let widths = header.indices.map { column in
            allRows.map { $0[column].text.count }.max() ?? 0
        }
        return allRows
            .map { row in
                guard let last = row.lastIndex(where: { !$0.text.isEmpty }) else { return "" }
                return (0...last)
                    .map { column in
                        let cell = row[column]
                        let padding = column == last ? "" : String(repeating: " ", count: widths[column] - cell.text.count)
                        return styler(cell.text, cell.style) + padding
                    }
                    .joined(separator: separator)
            }
            .joined(separator: "\n")
    }
}

extension TextTable {
    /// A table whose first column numbers the rows from 1, for picking.
    static func numbered(header: [String], rows: [[Cell]], styler: Styler) -> TextTable {
        TextTable(
            header: ["#"] + header,
            rows: rows.enumerated().map { [Cell("\($0.offset + 1)")] + $0.element },
            styler: styler
        )
    }
}
