extension Terminal {
    /// Writes `text` in `style`, if the terminal shows styles.
    func write(_ text: String, _ style: Style?) {
        write(styler(text, style))
    }
}
