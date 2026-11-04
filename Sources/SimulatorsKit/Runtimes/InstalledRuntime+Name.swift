extension InstalledRuntime {
    /// A display name such as `iOS 27.2`, or `iOS 27.2 (iPhone19-4)` for a device-specific runtime.
    public var name: String {
        name(stage: nil)
    }

    /// The display name with the release stage when known, such as `iOS 27.3 beta` or
    /// `iOS 27.2 beta 4 (iPhone19-4)`.
    public func name(stage: ReleaseStage?) -> String {
        let version = [platform.name, version, stage?.label].compactMap { $0 }.joined(separator: " ")
        return variant.map { "\(version) (\($0))" } ?? version
    }

    /// The device-specific part of the runtime identifier, if any.
    ///
    /// Regular runtimes have identifiers like `…SimRuntime.iOS-27-2`. Device-specific ones append
    /// a device model: `…SimRuntime.iOS-27-2-iPhone19-4` gives `iPhone19-4`. Such a runtime sits
    /// next to the regular one for the same version and isn't a duplicate of it.
    public var variant: String? {
        guard let lastComponent = runtimeIdentifier.split(separator: ".").last else { return nil }
        let remainder = lastComponent
            .split(separator: "-")
            .dropFirst()                                  // platform, e.g. "iOS"
            .drop { $0.allSatisfy(\.isNumber) }           // version, e.g. "27", "2"
        return remainder.isEmpty ? nil : remainder.joined(separator: "-")
    }
}
