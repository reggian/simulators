extension Terminal {
    /// Asks a question whose answer defaults to no. Only `y` or `yes` (any case) count as yes.
    func askYesNo(_ question: String) -> Bool {
        let answer = readLine(prompt: "\(question) [y/N] ")
        return ["y", "yes"].contains(answer?.trimmingCharacters(in: .whitespaces).lowercased())
    }
}
