/// Renders rows as left-aligned, space-separated columns, without trailing spaces when the last
/// cells are empty.
struct TextTable {
    let header: [String]
    let rows: [[String]]

    private let separator = "  "

    func render() -> String {
        let allRows = [header] + rows
        let widths = header.indices.map { column in
            allRows.map { $0[column].count }.max() ?? 0
        }
        return allRows
            .map { row in
                row.indices
                    .map { column in
                        column == row.indices.last ? row[column] : row[column].padding(to: widths[column])
                    }
                    .joined(separator: separator)
                    .trimmingTrailingSpaces()
            }
            .joined(separator: "\n")
    }
}

private extension String {
    func padding(to width: Int) -> String {
        self + String(repeating: " ", count: max(0, width - count))
    }

    func trimmingTrailingSpaces() -> String {
        String(self[..<(lastIndex { $0 != " " }.map(index(after:)) ?? startIndex)])
    }
}
