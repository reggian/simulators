import Foundation
import Testing
import SimulatorsKit
@testable import simulators

@Suite("Prune")
struct PruneFlowTests {
    private static let now = Date(timeIntervalSince1970: 1_793_000_000) // 2026-10-26
    private static let longAgo = "2026-04-09T10:00:00Z"                // 200 days before

    /// iOS 17.2 (not used for 200 days), iOS 27.2 beta 4 and release, watchOS 27.2 RC (used by
    /// Xcode 27.2 RC) and release.
    private let installedJSON = """
    {
      "O": { "identifier": "O", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-2",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "17.2", "build": "21C62",
             "sizeBytes": 7000000000, "deletable": true, "lastUsedAt": "\(PruneFlowTests.longAgo)" },
      "B": { "identifier": "B", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-2",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.2", "build": "24B5110a",
             "sizeBytes": 8000000000, "deletable": true },
      "R": { "identifier": "R", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-2",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.2", "build": "24B8117",
             "sizeBytes": 8000000000, "deletable": true },
      "W1": { "identifier": "W1", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-2",
              "platformIdentifier": "com.apple.platform.watchsimulator", "version": "27.2", "build": "24S117",
              "sizeBytes": 4000000000, "deletable": true },
      "W2": { "identifier": "W2", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-2",
              "platformIdentifier": "com.apple.platform.watchsimulator", "version": "27.2", "build": "24S118",
              "sizeBytes": 4000000000, "deletable": true }
    }
    """

    private let index = StubIndexLoader(entries: [
        .init(platform: "iphoneos", name: "iOS 27.2 beta 4 Simulator Runtime", version: "27.2", build: "24B5110a", architectures: ["arm64"], fileSize: 1),
        .init(platform: "iphoneos", name: "iOS 27.2 Simulator Runtime", version: "27.2", build: "24B8117", architectures: ["arm64"], fileSize: 1),
        .init(platform: "watchos", name: "watchOS 27.2 Release Candidate Simulator Runtime", version: "27.2", build: "24S117", architectures: ["arm64"], fileSize: 1),
        .init(platform: "watchos", name: "watchOS 27.2 Simulator Runtime", version: "27.2", build: "24S118", architectures: ["arm64"], fileSize: 1),
    ])

    @Test("Lists candidates with reasons, picks all by default, confirms and uninstalls")
    func interactiveDefaultsToAll() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["", "y"])

        try await sut.run(unusedForDays: 180, assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers == ["O", "B"])
        #expect(terminal.output.contains("not used for 6 months"))
        #expect(terminal.output.contains("superseded by iOS 27.2 (24B8117)"))
        #expect(terminal.output.contains(
            "Kept watchOS 27.2 RC (24S117): superseded by watchOS 27.2 (24S118), but used by Xcode 27.2."
        ))
        #expect(terminal.output.contains("Select runtimes to prune (e.g. 1 3, 2-4, all) [all]: "))
        #expect(terminal.output.contains("Uninstall 2 runtimes, freeing 15 GB? [y/N]"))
    }

    @Test("Uninstalls only the picked candidates")
    func picksSome() async throws {
        let (sut, runner, _) = makeSUT(answers: ["2", "y"])

        try await sut.run(unusedForDays: 180, assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers == ["B"])
    }

    @Test("Without the unused rule, offers superseded builds only")
    func supersededOnly() async throws {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        try await sut.run(unusedForDays: nil, assumeYes: true, dryRun: false)

        #expect(runner.deletedIdentifiers == ["B"])
    }

    @Test("With --yes, uninstalls every candidate without asking")
    func assumeYes() async throws {
        let (sut, runner, terminal) = makeSUT(isInteractive: false)

        try await sut.run(unusedForDays: 180, assumeYes: true, dryRun: false)

        #expect(runner.deletedIdentifiers == ["O", "B"])
        #expect(terminal.output.contains("2 runtimes, 15 GB"))
    }

    @Test("A dry run in a terminal goes through picking and confirming, then uninstalls nothing")
    func dryRunRehearsal() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["", "y"])

        try await sut.run(unusedForDays: 180, assumeYes: false, dryRun: true)

        #expect(runner.deletedIdentifiers.isEmpty)
        #expect(terminal.output.contains("Select runtimes to prune (e.g. 1 3, 2-4, all) [all]: "))
        #expect(terminal.output.contains("Uninstall 2 runtimes, freeing 15 GB (dry run)? [y/N]"))
        #expect(terminal.output.hasSuffix("Dry run: nothing was uninstalled."))
    }

    @Test("A dry run without a terminal shows the candidates and uninstalls nothing")
    func dryRun() async throws {
        let (sut, runner, terminal) = makeSUT(isInteractive: false)

        try await sut.run(unusedForDays: 180, assumeYes: false, dryRun: true)

        #expect(runner.deletedIdentifiers.isEmpty)
        #expect(terminal.output.hasSuffix("Would uninstall 2 runtimes, freeing 15 GB."))
    }

    @Test("Says when there's nothing to prune, and what it kept")
    func nothingToPrune() async throws {
        // Only the watchOS 27.2 RC (used by Xcode 27.2) and release.
        let watchOnly = """
        {
          "W1": { "identifier": "W1", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-2",
                  "platformIdentifier": "com.apple.platform.watchsimulator", "version": "27.2", "build": "24S117",
                  "deletable": true },
          "W2": { "identifier": "W2", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-2",
                  "platformIdentifier": "com.apple.platform.watchsimulator", "version": "27.2", "build": "24S118",
                  "deletable": true }
        }
        """
        let (sut, runner, terminal) = makeSUT(isInteractive: false, installedJSON: watchOnly)

        try await sut.run(unusedForDays: 180, assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers.isEmpty)
        #expect(terminal.output == """
            Nothing to prune.
            Kept watchOS 27.2 RC (24S117): superseded by watchOS 27.2 (24S118), but used by Xcode 27.2.
            """)
    }

    @Test("Fails without uninstalling anything", arguments: [
        (false, PruneError.selectionRequired),
        (true, .xcodesUnreadable(["Xcode 27.2"])),
    ])
    func failures(unreadableXcode: Bool, expected: PruneError) async {
        let (sut, runner, _) = makeSUT(isInteractive: false, unreadableXcode: unreadableXcode)

        await #expect(throws: expected) {
            try await sut.run(unusedForDays: 180, assumeYes: unreadableXcode, dryRun: false)
        }
        #expect(runner.deletedIdentifiers.isEmpty)
    }

    private func makeSUT(
        isInteractive: Bool = true,
        answers: [String] = [],
        unreadableXcode: Bool = false,
        installedJSON: String? = nil
    ) -> (PruneFlow, RecordingCommandRunner, ScriptedTerminal) {
        let runner = RecordingCommandRunner(runtimeListJSON: installedJSON ?? self.installedJSON)
        let terminal = ScriptedTerminal(isInteractive: isInteractive, answers: answers)
        let sut = PruneFlow(
            runner: runner,
            indexLoader: index,
            runtimeUsage: usage(unreadable: unreadableXcode),
            remounter: RuntimeRemounter(runner: runner, timeout: .zero),
            terminal: terminal,
            locale: Locale(identifier: "en_US_POSIX"),
            now: Self.now
        )
        return (sut, runner, terminal)
    }

    /// Xcode 27.2 uses the watchOS 27.2 RC, or can't be asked at all.
    private func usage(unreadable: Bool) -> RuntimeUsageService {
        let app = "/Applications/Xcode-27.2.0.app"
        let runner = RecordingCommandRunner(outputs: [
            ["/usr/bin/mdfind", "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"]: app,
            ["/usr/bin/env", "DEVELOPER_DIR=\(app)/Contents/Developer", "/usr/bin/xcrun", "simctl", "runtime", "match", "list", "-j"]:
                unreadable ? "not json" : #"{ "watchos27.2": { "chosenRuntimeBuild": "24S117", "platform": "com.apple.platform.watchos" } }"#,
        ])
        let xcodes = InstalledXcodeService(runner: runner) { _ in
            try PropertyListEncoder().encode(["CFBundleShortVersionString": "27.2", "ProductBuildVersion": "27B52"])
        }
        return RuntimeUsageService(runner: runner, xcodes: xcodes)
    }
}
