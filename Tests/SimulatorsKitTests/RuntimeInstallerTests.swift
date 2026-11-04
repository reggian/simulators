import Testing
import SimulatorsKit

@Suite("Runtime installer")
struct RuntimeInstallerTests {
    @Test("Downloads a runtime with xcodebuild by build and architecture variant")
    func installsByBuild() async throws {
        let runner = StubCommandRunner(output: .init())
        let runtime = AvailableRuntime(
            platform: SimulatorPlatform(identifier: "com.apple.platform.watchsimulator"),
            version: "27.2",
            build: "24S118",
            stage: .release,
            downloads: [RuntimeDownload(variant: .arm64, sizeBytes: 1)]
        )

        try await RuntimeInstaller(runner: runner).install(runtime, variant: .arm64)

        #expect(runner.commands == [[
            "/usr/bin/xcrun", "xcodebuild", "-downloadPlatform", "watchOS",
            "-buildVersion", "24S118", "-architectureVariant", "arm64",
        ]])
    }
}
