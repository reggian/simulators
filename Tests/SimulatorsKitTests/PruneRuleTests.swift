import Foundation
import Testing
import SimulatorsKit

@Suite("Prune rule")
struct PruneRuleTests {
    private static let iOS = SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator")
    private static let watchOS = SimulatorPlatform(identifier: "com.apple.platform.watchsimulator")

    // iOS 27.2 beta 4, RC and release; the iPhone19-4 release alone; watchOS 27.2 RC (used by an
    // Xcode) and release; iOS 27.1 with a build Apple's index doesn't know; iOS 26.5 alone.
    private let beta4 = runtime(iOS, "iOS-27-2", "27.2", "24B5110a")
    private let rc = runtime(iOS, "iOS-27-2", "27.2", "24B114")
    private let release = runtime(iOS, "iOS-27-2", "27.2", "24B8117")
    private let device = runtime(iOS, "iOS-27-2-iPhone19-4", "27.2", "24B91016s")
    private let watchRC = runtime(watchOS, "watchOS-27-2", "27.2", "24S117")
    private let watchRelease = runtime(watchOS, "watchOS-27-2", "27.2", "24S118")
    private let unknown = runtime(iOS, "iOS-27-1", "27.1", "24A99999")
    private let known = runtime(iOS, "iOS-27-1", "27.1", "24A94425")
    private let older = runtime(iOS, "iOS-26-5", "26.5", "23F77")

    @Test("Offers superseded builds, ranked by release stage before build number")
    func supersededBuilds() {
        let plan = PruneRule().plan(for: installed, stages: stages, usage: .empty)

        #expect(plan.candidates == [
            // Listing order, like `list`: by build number within a version.
            PruneCandidate(runtime: rc, reason: .superseded(by: release)),
            PruneCandidate(runtime: beta4, reason: .superseded(by: release)),
            PruneCandidate(runtime: watchRC, reason: .superseded(by: watchRelease)),
        ])
        #expect(plan.undecided == [[known, unknown]])
    }

    @Test("Keeps a superseded build an installed Xcode uses")
    func keepsUsedBuild() {
        let xcode = InstalledXcode(path: "/Applications/Xcode-27.2-RC.app", version: "27.2", build: "27B51")
        let usage = RuntimeUsage(choices: [(xcode, Self.watchOS, "24S117")])

        let plan = PruneRule().plan(for: installed, stages: stages, usage: usage)

        #expect(plan.candidates.map(\.runtime) == [rc, beta4])
        #expect(plan.keptInUse == [PruneCandidate(runtime: watchRC, reason: .superseded(by: watchRelease))])
    }

    @Test("Never offers a runtime simctl can't delete")
    func skipsUndeletable() {
        let bundled = runtime(Self.iOS, "iOS-27-2", "27.2", "24B5110a", deletable: false)

        let plan = PruneRule().plan(for: [bundled, release], stages: stages, usage: .empty)

        #expect(plan.candidates.isEmpty)
    }

    private var installed: [InstalledRuntime] {
        [older, known, unknown, release, rc, beta4, device, watchRelease, watchRC]
    }

    private var stages: ReleaseStageLookup {
        ReleaseStageLookup(available: [
            available(Self.iOS, "27.2", "24B5110a", .beta(4)),
            available(Self.iOS, "27.2", "24B114", .releaseCandidate),
            available(Self.iOS, "27.2", "24B8117", .release),
            available(Self.iOS, "27.2", "24B91016s", .release),
            available(Self.watchOS, "27.2", "24S117", .releaseCandidate),
            available(Self.watchOS, "27.2", "24S118", .release),
            available(Self.iOS, "27.1", "24A94425", .release),
            available(Self.iOS, "26.5", "23F77", .release),
        ])
    }

    private func available(_ platform: SimulatorPlatform, _ version: String, _ build: String, _ stage: ReleaseStage) -> AvailableRuntime {
        AvailableRuntime(platform: platform, version: version, build: build, stage: stage, downloads: [
            RuntimeDownload(variant: .arm64, sizeBytes: 1),
        ])
    }
}

private func runtime(
    _ platform: SimulatorPlatform,
    _ identifier: String,
    _ version: String,
    _ build: String,
    deletable: Bool = true
) -> InstalledRuntime {
    InstalledRuntime(
        identifier: build,
        runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.\(identifier)",
        platform: platform,
        version: version,
        build: build,
        architectures: ["arm64"],
        sizeBytes: 8_000_000_000,
        lastUsedAt: nil,
        isDeletable: deletable
    )
}
