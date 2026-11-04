import Testing
import SimulatorsKit

@Suite("Runtime matching")
struct InstalledRuntimeMatchingTests {
    private let regular = makeRuntime(runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-2", build: "24B8117")
    private let deviceSpecific = makeRuntime(runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4", build: "24B91016s")

    @Test("Matches by UUID, build or name, ignoring case", arguments: [
        "4D3A6E1B-0000-0000-0000-24B8117", "4d3a6e1b-0000-0000-0000-24b8117", "24B8117", "24b8117", " iOS 27.2 ",
    ])
    func matchesRegular(query: String) {
        #expect(regular.matches(query))
    }

    @Test("Platform and version match device-specific runtimes too, so the user is asked")
    func versionMatchesBoth() {
        #expect(regular.matches("ios 27.2"))
        #expect(deviceSpecific.matches("ios 27.2"))
    }

    @Test("The full name picks only the device-specific runtime")
    func fullNameIsSpecific() {
        #expect(deviceSpecific.matches("iOS 27.2 (iPhone19-4)"))
        #expect(!regular.matches("iOS 27.2 (iPhone19-4)"))
    }

    @Test("Matches the beta or RC label when the stage is known", arguments: [
        (ReleaseStage.beta(4), "iOS 27.2 beta 4", true),
        (.beta(nil), "ios 27.2 BETA", true),
        (.releaseCandidate, "iOS 27.2 rc", true),
        (.beta(4), "iOS 27.2 beta 3", false),
        (.release, "iOS 27.2 beta", false),
    ])
    func matchesLabel(stage: ReleaseStage, query: String, expected: Bool) {
        #expect(regular.matches(query, stage: stage) == expected)
    }

    @Test("Matches a device-specific runtime's full name with its label")
    func deviceSpecificLabel() {
        #expect(deviceSpecific.matches("iOS 27.2 beta 4 (iPhone19-4)", stage: .beta(4)))
        #expect(!regular.matches("iOS 27.2 beta 4 (iPhone19-4)", stage: .beta(4)))
    }

    @Test("Doesn't match partial input", arguments: ["iOS", "27.2", "24B81", "iOS 27"])
    func rejectsPartial(query: String) {
        #expect(!regular.matches(query))
    }

    private static func makeRuntime(runtimeIdentifier: String, build: String) -> InstalledRuntime {
        InstalledRuntime(
            identifier: "4D3A6E1B-0000-0000-0000-\(build)",
            runtimeIdentifier: runtimeIdentifier,
            platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
            version: "27.2",
            build: build,
            architectures: ["arm64"],
            sizeBytes: nil,
            lastUsedAt: nil
        )
    }
}
