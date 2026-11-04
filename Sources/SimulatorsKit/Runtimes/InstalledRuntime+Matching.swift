extension InstalledRuntime {
    /// Whether `query` refers to this runtime. Case-insensitive. Accepts:
    ///
    /// - the UUID, e.g. `0C734C3C-5798-4F82-B304-BCEABD2DD03C`
    /// - the build, e.g. `24B8117`
    /// - platform and version, e.g. `iOS 27.2`. This also matches device-specific runtimes of that
    ///   version, so the caller can ask which one was meant instead of guessing.
    /// - the full name, e.g. `iOS 27.2 (iPhone19-4)`
    public func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        return [identifier, build, "\(platform.name) \(version)", name]
            .contains { $0.caseInsensitiveCompare(query) == .orderedSame }
    }
}
