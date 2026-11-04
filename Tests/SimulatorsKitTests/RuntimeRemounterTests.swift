import Foundation
import Testing
import SimulatorsKit

@Suite("Runtime remounter")
struct RuntimeRemounterTests {
    private static let list = ["/usr/bin/xcrun", "simctl", "runtime", "list", "-j"]
    private static let scanAndMount = ["/usr/bin/xcrun", "simctl", "runtime", "scan-and-mount"]

    private let runtime = InstalledRuntime(
        identifier: "OLD",
        runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-1",
        platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
        version: "27.1",
        build: "24A94425",
        architectures: ["arm64"],
        sizeBytes: 7_870_000_000,
        lastUsedAt: nil
    )

    @Test("Scans, then waits until the runtime is back and ready")
    func waitsForRuntime() async throws {
        let runner = SequencedCommandRunner(outputs: [Self.list: [
            listJSON([]),
            listJSON([("NEW", "Mounting")]),
            listJSON([("NEW", "Ready")]),
        ]])
        let sleeps = SleepRecorder()
        let sut = RuntimeRemounter(runner: runner, pollInterval: .seconds(5), timeout: .seconds(60), sleep: sleeps.sleep)

        let back = try await sut.remount(runtime)

        #expect(back?.identifier == "NEW")
        #expect(runner.commands.first == Self.scanAndMount)
        #expect(sleeps.durations == [.seconds(5), .seconds(5)])
    }

    @Test("Gives up when the runtime isn't back within the timeout")
    func givesUp() async throws {
        let runner = SequencedCommandRunner(outputs: [Self.list: [listJSON([])]])
        let sleeps = SleepRecorder()
        let sut = RuntimeRemounter(runner: runner, pollInterval: .seconds(5), timeout: .seconds(10), sleep: sleeps.sleep)

        let back = try await sut.remount(runtime)

        #expect(back == nil)
        #expect(sleeps.durations == [.seconds(5), .seconds(5)])
    }

    /// `simctl runtime list -j` output with iOS 27.1 under each given UUID and state.
    private func listJSON(_ entries: [(identifier: String, state: String)]) -> Data {
        let runtimes = entries.map { entry in
            """
            "\(entry.identifier)": { "identifier": "\(entry.identifier)", "state": "\(entry.state)",
              "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-1",
              "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.1", "build": "24A94425" }
            """
        }
        return Data("{\(runtimes.joined(separator: ","))}".utf8)
    }
}
