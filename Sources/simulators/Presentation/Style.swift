/// A text style for terminal output.
enum Style: Sendable {
    case bold, dim, red, green, yellow

    /// The SGR parameter of the ANSI escape code.
    var code: String {
        switch self {
        case .bold: "1"
        case .dim: "2"
        case .red: "31"
        case .green: "32"
        case .yellow: "33"
        }
    }
}
