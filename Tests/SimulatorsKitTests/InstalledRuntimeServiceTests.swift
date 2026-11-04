import Foundation
import Testing
import SimulatorsKit

@Suite("Installed runtimes")
struct InstalledRuntimeServiceTests {
    @Test("Lists runtimes from simctl, sorted by platform, version and build")
    func listsRuntimesInOrder() async throws {
        let runner = StubCommandRunner(output: try fixture("simctl-runtime-list.json"))
        let sut = InstalledRuntimeService(runner: runner)

        let runtimes = try await sut.installedRuntimes()

        #expect(runner.commands == [["/usr/bin/xcrun", "simctl", "runtime", "list", "-j"]])
        #expect(runtimes.map(\.name) == [
            "iOS 17.2",
            "iOS 26.5",
            "iOS 27.1",
            "iOS 27.2",
            "iOS 27.2 (iPhone19-4)",
            "watchOS 26.5",
            "watchOS 27.0",
            "watchOS 27.2",
        ])
        #expect(runtimes.map(\.build) == [
            "21C62", "23F77", "24A94425", "24B8117", "24B91016s", "23T570", "24R362", "24S118",
        ])
    }

    @Test("Decodes a runtime with optional fields missing and an unknown platform")
    func decodesSparseRuntime() async throws {
        let json = """
        {
          "A": {
            "identifier": "A",
            "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.carOS-1-0",
            "platformIdentifier": "com.apple.platform.carsimulator",
            "version": "1.0",
            "build": "1A1"
          }
        }
        """
        let sut = InstalledRuntimeService(runner: StubCommandRunner(output: Data(json.utf8)))

        let runtime = try #require(try await sut.installedRuntimes().first)

        #expect(runtime.name == "carsimulator 1.0")
        #expect(runtime.architectures.isEmpty)
        #expect(runtime.sizeBytes == nil)
        #expect(runtime.lastUsedAt == nil)
    }

    @Test("Skips a runtime simctl is still registering instead of failing")
    func skipsIncompleteRuntime() async throws {
        let json = """
        {
          "A": { "identifier": "A", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-2",
                 "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "17.2", "build": "21C62" },
          "B": { "identifier": "B", "state": "Mounting" }
        }
        """
        let sut = InstalledRuntimeService(runner: StubCommandRunner(output: Data(json.utf8)))

        let runtimes = try await sut.installedRuntimes()

        #expect(runtimes.map(\.identifier) == ["A"])
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}
