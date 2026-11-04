import Foundation
import Testing
import SimulatorsKit
@testable import simulators

@Suite("Uninstall")
struct UninstallFlowTests {
    /// iOS 17.2, iOS 27.2 and its iPhone19-4 variant, and a bundled watchOS runtime that can't be deleted.
    /// Only iOS 17.2 reports itself ready, so only it can come back after a remount.
    private let runtimeListJSON = """
    {
      "A": { "identifier": "A", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-2",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "17.2", "build": "21C62",
             "sizeBytes": 7000000000, "deletable": true, "state": "Ready" },
      "B": { "identifier": "B", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-2",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.2", "build": "24B8117",
             "sizeBytes": 8000000000, "deletable": true },
      "C": { "identifier": "C", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.2", "build": "24B91016s",
             "sizeBytes": 8000000000, "deletable": true },
      "D": { "identifier": "D", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.watchOS-27-0",
             "platformIdentifier": "com.apple.platform.watchsimulator", "version": "27.0", "build": "24R362",
             "deletable": false }
    }
    """

    @Test("Without arguments, lists deletable runtimes, deletes the picked ones after confirmation")
    func interactiveHappyPath() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["1 3", "y"])

        try await sut.run(queries: [], assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers == ["A", "C"])
        #expect(!terminal.output.contains("watchOS 27.0"))
        #expect(terminal.output.contains("Uninstall 2 runtimes, freeing 15 GB? [y/N]"))
        #expect(terminal.output.contains("Done. Freed 15 GB."))
    }

    @Test("Asks again after an invalid selection")
    func repromptsOnInvalidSelection() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["9", "2", "y"])

        try await sut.run(queries: [], assumeYes: false, dryRun: false)

        #expect(terminal.output.contains("9 isn't in the list. Pick numbers from 1 to 3."))
        #expect(runner.deletedIdentifiers == ["B"])
    }

    @Test("Deletes nothing unless the confirmation is yes", arguments: ["", "n", "no", "maybe"])
    func declined(answer: String) async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["1", answer])

        try await sut.run(queries: [], assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers.isEmpty)
        #expect(terminal.output.contains("Cancelled. Nothing was uninstalled."))
    }

    @Test("Uninstalls named runtimes without a terminal when --yes is given")
    func nonInteractiveWithYes() async throws {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        try await sut.run(queries: ["21C62", "iOS 27.2 (iPhone19-4)"], assumeYes: true, dryRun: false)

        #expect(runner.deletedIdentifiers == ["A", "C"])
    }

    @Test("Asks which runtime was meant when a name matches several")
    func ambiguousInteractive() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["2", "y"])

        try await sut.run(queries: ["ios 27.2"], assumeYes: false, dryRun: false)

        #expect(terminal.output.contains("\"ios 27.2\" matches several runtimes. Select"))
        #expect(runner.deletedIdentifiers == ["C"])
    }

    @Test("Without a terminal, fails instead of prompting", arguments: [
        ([], false, UninstallError.runtimeArgumentRequired),
        (["21C62"], false, .confirmationRequired),
        (["iOS 27.2"], true, .ambiguous("iOS 27.2", matches: ["iOS 27.2 (24B8117)", "iOS 27.2 (iPhone19-4) (24B91016s)"])),
    ] as [([String], Bool, UninstallError)])
    func nonInteractiveFailures(queries: [String], assumeYes: Bool, expected: UninstallError) async {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        await #expect(throws: expected) {
            try await sut.run(queries: queries, assumeYes: assumeYes, dryRun: false)
        }
        #expect(runner.deletedIdentifiers.isEmpty)
    }

    @Test("Refuses unknown and undeletable runtimes", arguments: [
        ("26.0", UninstallError.noMatch("26.0")),
        ("24R362", .notDeletable("watchOS 27.0")),
    ])
    func refusesUnusableQueries(query: String, expected: UninstallError) async {
        let (sut, runner, _) = makeSUT()

        await #expect(throws: expected) {
            try await sut.run(queries: [query], assumeYes: true, dryRun: false)
        }
        #expect(runner.deletedIdentifiers.isEmpty)
    }

    @Test("When simctl keeps a runtime's files, waits for it to come back and deletes it again")
    func reclaimsKeptFiles() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["1 2", "y"], deleteFailures: ["A": kept])

        try await sut.run(queries: [], assumeYes: false, dryRun: false)

        #expect(runner.deletedIdentifiers == ["A", "A", "B"])
        #expect(runner.commands.contains(["/usr/bin/xcrun", "simctl", "runtime", "scan-and-mount"]))
        #expect(terminal.output.contains("Waiting for macOS to register iOS 17.2 again…"))
        #expect(terminal.output.contains("Done. Freed 15 GB."))
    }

    @Test("Carries on when a runtime's files stay, and counts only what was freed", arguments: [
        ("1 2", ["A", "B"], "7 GB"),
        ("2", ["B"], nil),
    ] as [(String, [String], String?)])
    func filesStay(selection: String, deleted: [String], freed: String?) async throws {
        // iOS 27.2 never reports itself ready again, so the retry gives up.
        let (sut, runner, terminal) = makeSUT(answers: [selection, "y"], deleteFailures: ["B": kept])

        await #expect(throws: UninstallError.incomplete(failed: ["iOS 27.2 (24B8117)"], freed: freed)) {
            try await sut.run(queries: [], assumeYes: false, dryRun: false)
        }
        #expect(runner.deletedIdentifiers == deleted)
        #expect(terminal.output.contains(
            "Its files (8 GB) are still in /System/Library/AssetsV2/a.asset. To free them, run `xcrun simctl runtime scan-and-mount`"
        ))
        #expect(!terminal.output.contains("Done."))
    }

    @Test("Labels betas it knows from Apple's index")
    func labelsBetas() async throws {
        let index = StubIndexLoader(entries: [
            .init(platform: "iphoneos", name: "iOS 27.2 beta 4 Simulator Runtime", version: "27.2", build: "24B91016s", architectures: ["arm64"], fileSize: 1),
        ])
        let (sut, _, terminal) = makeSUT(isInteractive: false, index: index)

        try await sut.run(queries: ["24B91016s"], assumeYes: false, dryRun: true)

        #expect(terminal.output == "Would uninstall iOS 27.2 beta 4 (iPhone19-4) (24B91016s)")
    }

    @Test("Warns before uninstalling a runtime an installed Xcode uses")
    func warnsAboutUsedRuntime() async throws {
        let (sut, _, terminal) = makeSUT(answers: ["n"], usage: usage(xcodeUsing: "24B8117"))

        try await sut.run(queries: ["24B8117"], assumeYes: false, dryRun: false)

        #expect(terminal.output.contains("  iOS 27.2 (24B8117), used by Xcode 27.2"))
        #expect(terminal.output.contains("Xcode uses these runtimes to build, preview and run simulators"))
    }

    @Test("A dry run shows what would be uninstalled and deletes nothing")
    func dryRun() async throws {
        let (sut, runner, terminal) = makeSUT(isInteractive: false)

        try await sut.run(queries: ["21C62"], assumeYes: false, dryRun: true)

        #expect(runner.commands == [RecordingCommandRunner.listCommand])
        #expect(terminal.output == "Would uninstall iOS 17.2 (21C62)")
    }

    private let kept = RuntimeAssetKept(assetPath: "/System/Library/AssetsV2/a.asset")

    private func makeSUT(
        isInteractive: Bool = true,
        answers: [String] = [],
        deleteFailures: [String: any Error] = [:],
        index: StubIndexLoader = StubIndexLoader(entries: []),
        usage: RuntimeUsageService = RuntimeUsageService(runner: RecordingCommandRunner())
    ) -> (UninstallFlow, RecordingCommandRunner, ScriptedTerminal) {
        let runner = RecordingCommandRunner(runtimeListJSON: runtimeListJSON, deleteFailures: deleteFailures)
        let terminal = ScriptedTerminal(isInteractive: isInteractive, answers: answers)
        let sut = UninstallFlow(
            runner: runner,
            indexLoader: index,
            runtimeUsage: usage,
            remounter: RuntimeRemounter(runner: runner, timeout: .zero),
            terminal: terminal,
            locale: Locale(identifier: "en_US_POSIX")
        )
        return (sut, runner, terminal)
    }

    /// Usage where one installed Xcode, 27.2, uses the iOS runtime with `build`.
    private func usage(xcodeUsing build: String) -> RuntimeUsageService {
        let app = "/Applications/Xcode-27.2.0.app"
        let runner = RecordingCommandRunner(outputs: [
            ["/usr/bin/mdfind", "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"]: app,
            ["/usr/bin/env", "DEVELOPER_DIR=\(app)/Contents/Developer", "/usr/bin/xcrun", "simctl", "runtime", "match", "list", "-j"]:
                #"{ "iphoneos27.2": { "chosenRuntimeBuild": "\#(build)", "platform": "com.apple.platform.iphoneos" } }"#,
        ])
        let xcodes = InstalledXcodeService(runner: runner) { _ in
            try PropertyListEncoder().encode(["CFBundleShortVersionString": "27.2", "ProductBuildVersion": "27B52"])
        }
        return RuntimeUsageService(runner: runner, xcodes: xcodes)
    }
}
