import Foundation
import Testing
import SimulatorsKit
@testable import simulators

@Suite("Install")
struct InstallFlowTests {
    /// iOS 26.5 (arm64 and universal), 27.1, 27.2 and its iPhone19-4 variant, and watchOS 27.2.
    private let index = StubIndexLoader(entries: [
        .init(platform: "iphoneos", name: "iOS 26.5 Simulator Runtime", version: "26.5", build: "23F77", architectures: ["arm64"], fileSize: 8_500_000_000),
        .init(platform: "iphoneos", name: "iOS 26.5 Simulator Runtime", version: "26.5", build: "23F77", architectures: ["arm64", "x86_64"], fileSize: 10_600_000_000),
        .init(platform: "iphoneos", name: "iOS 27.1 Simulator Runtime", version: "27.1", build: "24A94425", architectures: ["arm64"], fileSize: 7_850_000_000),
        .init(platform: "iphoneos", name: "iOS 27.2 Simulator Runtime", version: "27.2", build: "24B8117", architectures: ["arm64"], fileSize: 8_320_000_000),
        .init(platform: "iphoneos", name: "iOS 27.2 Simulator Runtime", version: "27.2", build: "24B91016s", architectures: ["arm64"], fileSize: 8_320_000_000),
        .init(platform: "watchos", name: "watchOS 27.2 Simulator Runtime", version: "27.2", build: "24S118", architectures: ["arm64"], fileSize: 3_890_000_000),
    ])

    /// Only iOS 27.1 is installed.
    private let installedJSON = """
    {
      "A": { "identifier": "A", "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-27-1",
             "platformIdentifier": "com.apple.platform.iphonesimulator", "version": "27.1", "build": "24A94425",
             "deletable": true, "state": "Ready" }
    }
    """

    @Test("Without arguments, lists runtimes that aren't installed and installs the picked ones")
    func interactiveHappyPath() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["1 4", "y"])

        try await sut.run(arguments: [], variant: nil, assumeYes: false, dryRun: false)

        #expect(runner.attachedCommands == [
            xcodebuild("iOS", "23F77", "arm64"),
            xcodebuild("watchOS", "24S118", "arm64"),
        ])
        #expect(!terminal.output.contains("24A94425"))
        #expect(terminal.output.contains("1 installed runtime isn't shown."))
        #expect(terminal.output.contains("Install 2 runtimes, downloading 12.39 GB? [y/N]"))
        #expect(terminal.output.contains("Installing iOS 26.5 (23F77, arm64, 8.5 GB)…"))
        #expect(terminal.output.hasSuffix("Done."))
    }

    @Test("Installs runtimes named by platform, version or build", arguments: [
        (["iOS", "26.5"], ["23F77"]),
        (["watchOS", "iOS 26.5"], ["24S118", "23F77"]),
        (["24b8117"], ["24B8117"]),
    ])
    func namedRuntimes(arguments: [String], builds: [String]) async throws {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        try await sut.run(arguments: arguments, variant: nil, assumeYes: true, dryRun: false)

        #expect(runner.attachedCommands.map { $0[5] } == builds)
    }

    @Test("Installs the asked-for architecture variant")
    func variant() async throws {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        try await sut.run(arguments: ["iOS 26.5"], variant: .universal, assumeYes: true, dryRun: false)

        #expect(runner.attachedCommands == [xcodebuild("iOS", "23F77", "universal")])
    }

    @Test("Skips runtimes that are already installed")
    func alreadyInstalled() async throws {
        let (sut, runner, terminal) = makeSUT(isInteractive: false)

        try await sut.run(arguments: ["iOS 27.1"], variant: nil, assumeYes: true, dryRun: false)

        #expect(runner.attachedCommands.isEmpty)
        #expect(terminal.output == "iOS 27.1 (24A94425) is already installed.")
    }

    @Test("Asks which runtime was meant when a version has several builds")
    func ambiguousInteractive() async throws {
        let (sut, runner, terminal) = makeSUT(answers: ["2", "y"])

        try await sut.run(arguments: ["iOS 27.2"], variant: nil, assumeYes: false, dryRun: false)

        #expect(terminal.output.contains("\"iOS 27.2\" matches several runtimes. Select"))
        #expect(runner.attachedCommands == [xcodebuild("iOS", "24B91016s", "arm64")])
    }

    @Test("Downloads nothing unless the confirmation is yes", arguments: ["", "n", "maybe"])
    func declined(answer: String) async throws {
        let (sut, runner, terminal) = makeSUT(answers: [answer])

        try await sut.run(arguments: ["watchOS"], variant: nil, assumeYes: false, dryRun: false)

        #expect(runner.attachedCommands.isEmpty)
        #expect(terminal.output.contains("Cancelled. Nothing was installed."))
    }

    @Test("Without a terminal, needs --yes instead of asking")
    func confirmationRequired() async {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        await #expect(throws: InstallError.confirmationRequired) {
            try await sut.run(arguments: ["watchOS"], variant: nil, assumeYes: false, dryRun: false)
        }
        #expect(runner.attachedCommands.isEmpty)
    }

    @Test("Fails without downloading anything", arguments: [
        ([], nil, InstallError.runtimeArgumentRequired),
        (["iOS 99.0"], nil, .noMatch("iOS 99.0")),
        (["iOS 27.2"], nil, .ambiguous("iOS 27.2", matches: ["iOS 27.2 (24B8117)", "iOS 27.2 (24B91016s)"])),
        (["watchOS"], .universal, .variantUnavailable("watchOS 27.2 (24S118)", requested: "universal", offered: ["arm64"])),
    ] as [([String], ArchitectureVariant?, InstallError)])
    func failures(arguments: [String], variant: ArchitectureVariant?, expected: InstallError) async {
        let (sut, runner, _) = makeSUT(isInteractive: false)

        await #expect(throws: expected) {
            try await sut.run(arguments: arguments, variant: variant, assumeYes: true, dryRun: false)
        }
        #expect(runner.attachedCommands.isEmpty)
    }

    @Test("Carries on after a download fails, then reports it")
    func partialFailure() async throws {
        let failure = CommandFailure(command: ["xcodebuild"], exitCode: 70, standardError: "")
        let (sut, runner, _) = makeSUT(isInteractive: false, attachedFailures: ["23F77": failure])

        await #expect(throws: InstallError.incomplete(failed: ["iOS 26.5 (23F77)"])) {
            try await sut.run(arguments: ["iOS 26.5", "watchOS"], variant: nil, assumeYes: true, dryRun: false)
        }
        #expect(runner.attachedCommands.map { $0[5] } == ["23F77", "24S118"])
    }

    @Test("A dry run shows what would be installed and downloads nothing")
    func dryRun() async throws {
        let (sut, runner, terminal) = makeSUT(isInteractive: false)

        try await sut.run(arguments: ["watchOS"], variant: nil, assumeYes: false, dryRun: true)

        #expect(runner.attachedCommands.isEmpty)
        #expect(terminal.output == "Would install watchOS 27.2 (24S118, arm64, 3.89 GB)")
    }

    private func xcodebuild(_ platform: String, _ build: String, _ variant: String) -> [String] {
        ["/usr/bin/xcrun", "xcodebuild", "-downloadPlatform", platform, "-buildVersion", build, "-architectureVariant", variant]
    }

    private func makeSUT(
        isInteractive: Bool = true,
        answers: [String] = [],
        attachedFailures: [String: any Error] = [:]
    ) -> (InstallFlow, RecordingCommandRunner, ScriptedTerminal) {
        let runner = RecordingCommandRunner(runtimeListJSON: installedJSON, attachedFailures: attachedFailures)
        let terminal = ScriptedTerminal(isInteractive: isInteractive, answers: answers)
        let sut = InstallFlow(runner: runner, indexLoader: index, terminal: terminal, locale: Locale(identifier: "en_US_POSIX"))
        return (sut, runner, terminal)
    }
}
