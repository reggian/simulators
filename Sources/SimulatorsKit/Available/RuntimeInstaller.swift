/// Downloads and installs simulator runtimes with `xcodebuild`.
public struct RuntimeInstaller: Sendable {
    private let runner: any CommandRunner

    public init(runner: any CommandRunner = ProcessCommandRunner()) {
        self.runner = runner
    }

    /// Downloads and installs one variant of `runtime`, showing `xcodebuild`'s progress in the
    /// terminal. Identifies the runtime by build, never by version alone.
    public func install(_ runtime: AvailableRuntime, variant: ArchitectureVariant) async throws {
        try await runner.runAttached("/usr/bin/xcrun", [
            "xcodebuild", "-downloadPlatform", runtime.platform.name,
            "-buildVersion", runtime.build,
            "-architectureVariant", variant.rawValue,
        ])
    }
}
