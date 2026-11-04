import Testing
import SimulatorsKit

@Suite("Runtime queries")
struct RuntimeQueryTests {
    private static let iOS = SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator")
    private static let watchOS = SimulatorPlatform(identifier: "com.apple.platform.watchsimulator")

    @Test("Parses platforms, versions and builds from arguments", arguments: [
        (["iOS", "27.2"], [RuntimeQuery.platform(iOS, version: "27.2")]),
        (["ios 27.2"], [.platform(iOS, version: "27.2")]),
        (["watchOS"], [.platform(watchOS, version: nil)]),
        (["24B8117", "iOS", "27.1", "watchOS"], [.build("24B8117"), .platform(iOS, version: "27.1"), .platform(watchOS, version: nil)]),
        (["iOS", "24B8117"], [.platform(iOS, version: nil), .build("24B8117")]),
        (["iOS", "27.2", "beta", "4", "watchOS 27.3 beta"], [.stage(iOS, version: "27.2", .beta(4)), .stage(watchOS, version: "27.3", .beta(nil))]),
        (["ios 27.1 rc"], [.stage(iOS, version: "27.1", .releaseCandidate)]),
    ])
    func parses(arguments: [String], expected: [RuntimeQuery]) {
        #expect(RuntimeQuery.parse(arguments) == expected)
    }

    @Test("Matches builds, versions and a platform's newest release", arguments: [
        ("24b8117", ["24B8117"]),
        ("iOS 27.1", ["24A94425"]),            // the release, not the RC
        ("iOS 27.2", ["24B8117", "24B91016s"]), // regular and device-specific: the user chooses
        ("iOS 27.3", ["24C5037i"]),            // no release yet: the newest beta
        ("iOS", ["24B8117", "24B91016s"]),     // newest release, not the 27.3 beta
        ("watchOS", ["24S118"]),
        ("iOS 99.0", []),
        ("iOS 27.2 beta 4", ["24B5110a"]),
        ("iOS 27.1 RC", ["24A94232"]),
        ("iOS 27.3 beta", ["24C5037i"]),
        ("iOS 27.2 beta 3", []),
    ])
    func matches(query: String, expected: [String]) async throws {
        let available = try await AvailableRuntimeService(loader: try StubIndexLoader.fixture()).availableRuntimes()
        let sut = try #require(RuntimeQuery.parse([query]).first)

        #expect(sut.matches(in: available).map(\.build) == expected)
    }
}
