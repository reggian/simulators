/// A simulator runtime Apple offers for download, as listed in its runtime index.
public struct AvailableRuntime: Equatable, Sendable {
    public let platform: SimulatorPlatform
    /// The OS version, for example `27.2`.
    public let version: String
    /// Apple's build number, for example `24B8117`.
    public let build: String
    public let stage: ReleaseStage
    /// The architecture variants on offer, arm64 first. Never empty.
    public let downloads: [RuntimeDownload]

    public init(
        platform: SimulatorPlatform,
        version: String,
        build: String,
        stage: ReleaseStage,
        downloads: [RuntimeDownload]
    ) {
        precondition(!downloads.isEmpty, "A runtime needs at least one download")
        self.platform = platform
        self.version = version
        self.build = build
        self.stage = stage
        self.downloads = downloads.sorted { $0.variant.sortOrder < $1.variant.sortOrder }
    }

    /// A display name such as `iOS 27.2` or `iOS 27.3 beta 2`.
    public var name: String {
        let base = "\(platform.name) \(version)"
        return stage.label.map { "\(base) \($0)" } ?? base
    }

    /// The download to use when none is asked for: arm64 when offered, as Xcode does.
    public var defaultDownload: RuntimeDownload {
        downloads[0]
    }

    public func download(for variant: ArchitectureVariant) -> RuntimeDownload? {
        downloads.first { $0.variant == variant }
    }
}

private extension ArchitectureVariant {
    var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? Int.max
    }
}
