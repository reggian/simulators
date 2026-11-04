extension InstalledRuntime {
    /// Whether `query` refers to this runtime. Case-insensitive. Accepts:
    ///
    /// - the UUID, e.g. `0C734C3C-5798-4F82-B304-BCEABD2DD03C`
    /// - the build, e.g. `24B8117`
    /// - platform and version, e.g. `iOS 27.2`. This also matches device-specific runtimes of that
    ///   version, so the caller can ask which one was meant instead of guessing.
    /// - the full name, e.g. `iOS 27.2 (iPhone19-4)`
    /// - with `stage` known: platform, version and label, e.g. `iOS 27.3 beta` or `iOS 27.2 RC`, and
    ///   the full name with the label, e.g. `iOS 27.2 beta 4 (iPhone19-4)`
    ///
    /// - Parameter stage: The runtime's release stage from Apple's index, if known. Installed
    ///   runtimes don't record it themselves.
    public func matches(_ query: String, stage: ReleaseStage? = nil) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        var names = [identifier, build, "\(platform.name) \(version)", name]
        if let label = stage?.label {
            names += ["\(platform.name) \(version) \(label)", name(stage: stage)]
        }
        return names.contains { $0.caseInsensitiveCompare(query) == .orderedSame }
    }
}
