import Foundation
import Testing
import SimulatorsKit

@Suite("Runtime usage")
struct RuntimeUsageServiceTests {
    private static let spotlight = ["/usr/bin/mdfind", "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"]

    @Test("Asks each Xcode which runtime builds it uses")
    func readsEachXcode() async throws {
        // Xcode 27.2's answer is real (`Fixtures/simctl-runtime-match-list.json`); Xcode 26.4's is made up.
        let older = """
        { "iphoneos26.4": { "chosenRuntimeBuild": "23E244", "platform": "com.apple.platform.iphoneos" },
          "watchos26.4": { "chosenRuntimeBuild": "24S118", "platform": "com.apple.platform.watchos" } }
        """
        let runner = SequencedCommandRunner(outputs: [
            Self.spotlight: [Data("/Applications/Xcode-26.4.app\n/Applications/Xcode-27.2.0.app\n".utf8)],
            matchList(for: "/Applications/Xcode-26.4.app"): [Data(older.utf8)],
            matchList(for: "/Applications/Xcode-27.2.0.app"): [try fixture("simctl-runtime-match-list.json")],
        ])
        let sut = RuntimeUsageService(runner: runner, xcodes: xcodes(runner, versions: [
            "/Applications/Xcode-26.4.app": "26.4",
            "/Applications/Xcode-27.2.0.app": "27.2",
        ]))

        let usage = try await sut.usage()

        #expect(usage.xcodes(using: runtime("iOS", "24B8117")).map(\.name) == ["Xcode 27.2"])
        #expect(usage.xcodes(using: runtime("iOS", "23E244")).map(\.name) == ["Xcode 26.4"])
        #expect(usage.xcodes(using: runtime("watchOS", "24S118")).map(\.name) == ["Xcode 26.4", "Xcode 27.2"])
        #expect(usage.xcodes(using: runtime("iOS", "24B91016s")).isEmpty)
    }

    @Test("Skips an Xcode that can't be asked")
    func skipsBrokenXcode() async throws {
        let runner = SequencedCommandRunner(outputs: [
            Self.spotlight: [Data("/Applications/Xcode-27.2.0.app\n".utf8)],
            matchList(for: "/Applications/Xcode-27.2.0.app"): [Data("not json".utf8)],
        ])
        let sut = RuntimeUsageService(runner: runner, xcodes: xcodes(runner, versions: ["/Applications/Xcode-27.2.0.app": "27.2"]))

        let usage = try await sut.usage()

        #expect(usage.xcodes(using: runtime("iOS", "24B8117")).isEmpty)
    }

    private func matchList(for app: String) -> [String] {
        ["/usr/bin/env", "DEVELOPER_DIR=\(app)/Contents/Developer", "/usr/bin/xcrun", "simctl", "runtime", "match", "list", "-j"]
    }

    private func xcodes(_ runner: any CommandRunner, versions: [String: String]) -> InstalledXcodeService {
        InstalledXcodeService(runner: runner) { path in
            let app = path.replacingOccurrences(of: "/Contents/version.plist", with: "")
            guard let version = versions[app] else { throw CocoaError(.fileNoSuchFile) }
            return try PropertyListEncoder().encode(["CFBundleShortVersionString": version, "ProductBuildVersion": "X"])
        }
    }

    private func runtime(_ platform: String, _ build: String) -> InstalledRuntime {
        InstalledRuntime(
            identifier: build,
            runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.\(platform)",
            platform: SimulatorPlatform.named(platform)!,
            version: "1.0",
            build: build,
            architectures: [],
            sizeBytes: nil,
            lastUsedAt: nil
        )
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}
