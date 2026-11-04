import Foundation
import Testing
import SimulatorsKit

@Suite("Runtime uninstaller")
struct RuntimeUninstallerTests {
    private let runtime = InstalledRuntime(
        identifier: "0C734C3C-5798-4F82-B304-BCEABD2DD03C",
        runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-17-2",
        platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
        version: "17.2",
        build: "21C62",
        architectures: ["arm64"],
        sizeBytes: nil,
        lastUsedAt: nil
    )

    private let runtimeWithFiles = InstalledRuntime(
        identifier: "A",
        runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-1",
        platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
        version: "27.1",
        build: "24A94425",
        architectures: ["arm64"],
        sizeBytes: nil,
        lastUsedAt: nil,
        path: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/1d40f1.asset/AssetData"
    )

    @Test("Deletes a runtime by its UUID, never by version or build")
    func deletesByIdentifier() async throws {
        let runner = StubCommandRunner(output: Data())
        let sut = RuntimeUninstaller(runner: runner)

        try await sut.uninstall(runtime)

        #expect(runner.commands == [
            ["/usr/bin/xcrun", "simctl", "runtime", "delete", "0C734C3C-5798-4F82-B304-BCEABD2DD03C"],
        ])
    }

    @Test("Waits for the runtime's files to disappear after deleting", arguments: [0, 3])
    func waitsForFilesToDisappear(checksUntilGone: Int) async throws {
        let files = FileChecks(existsFor: checksUntilGone)
        let sleeps = SleepRecorder()
        let sut = RuntimeUninstaller(
            runner: StubCommandRunner(output: Data()),
            fileExists: files.exists,
            pollInterval: .seconds(1),
            removalTimeout: .seconds(10),
            sleep: sleeps.sleep
        )

        try await sut.uninstall(runtimeWithFiles)

        #expect(sleeps.durations.count == checksUntilGone)
    }

    @Test("Reports kept files when simctl succeeds but the files stay")
    func filesStayAfterSuccess() async {
        let sleeps = SleepRecorder()
        let sut = RuntimeUninstaller(
            runner: StubCommandRunner(output: Data()),
            fileExists: { _ in true },
            pollInterval: .seconds(1),
            removalTimeout: .seconds(2),
            sleep: sleeps.sleep
        )

        await #expect(throws: RuntimeAssetKept(assetPath: runtimeWithFiles.path)) {
            try await sut.uninstall(runtimeWithFiles)
        }
        #expect(sleeps.durations == [.seconds(1), .seconds(1)])
    }

    /// Captured from `simctl runtime delete` on Xcode 27.2, macOS 27.2.
    @Test("Reports a runtime whose files simctl left on disk")
    func assetKept() async {
        let stderr = """
            An error was encountered processing the command \
            (domain=com.apple.CoreSimulator.simdiskimaged.SimDiskImageError, code=30):
            Removed the runtime, but did not reclaim its MobileAsset: \
            /System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/1d40f1.asset/AssetData/
            Run 'xcrun simctl runtime scan-and-mount' to re-register the runtime, then delete it again.
            """
        let sut = RuntimeUninstaller(runner: StubCommandRunner(failure: failure(exitCode: 30, stderr)))

        await #expect(throws: RuntimeAssetKept(
            assetPath: "/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/1d40f1.asset/AssetData/"
        )) {
            try await sut.uninstall(runtime)
        }
    }

    @Test("Passes other failures through")
    func otherFailure() async {
        let other = failure(exitCode: 1, "Invalid runtime")
        let sut = RuntimeUninstaller(runner: StubCommandRunner(failure: other))

        await #expect(throws: other) {
            try await sut.uninstall(runtime)
        }
    }

    private func failure(exitCode: Int32, _ stderr: String) -> CommandFailure {
        CommandFailure(command: ["/usr/bin/xcrun", "simctl"], exitCode: exitCode, standardError: stderr)
    }
}

/// Reports a file as existing for the first `existsFor` checks, then as gone.
private final class FileChecks: @unchecked Sendable {
    private let lock = NSLock()
    private var remaining: Int

    init(existsFor checks: Int) {
        remaining = checks
    }

    var exists: @Sendable (String) -> Bool {
        { [self] _ in
            lock.withLock {
                defer { remaining -= 1 }
                return remaining > 0
            }
        }
    }
}
