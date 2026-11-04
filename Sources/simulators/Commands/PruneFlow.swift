import Foundation
import SimulatorsKit

/// Finds runtimes worth removing, lets the user pick (all by default), confirms, and deletes them.
struct PruneFlow {
    private let installedRuntimes: InstalledRuntimeService
    private let availableRuntimes: AvailableRuntimeService
    private let runtimeUsage: RuntimeUsageService
    private let uninstaller: RuntimeUninstaller
    private let remounter: RuntimeRemounter
    private let terminal: any Terminal
    private let locale: Locale
    private let now: Date

    /// - Parameters:
    ///   - indexLoader: Apple's runtime index, which ranks builds of one version.
    ///   - runtimeUsage: Reads which Xcodes use which runtime. Defaults to one using `runner`.
    ///   - remounter: Brings back runtimes whose files `simctl` kept. Defaults to one using `runner`.
    init(
        runner: any CommandRunner = ProcessCommandRunner(),
        indexLoader: any RuntimeIndexLoader = AppleRuntimeIndexLoader(),
        runtimeUsage: RuntimeUsageService? = nil,
        remounter: RuntimeRemounter? = nil,
        terminal: any Terminal,
        locale: Locale = .current,
        now: Date = .now
    ) {
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.availableRuntimes = AvailableRuntimeService(loader: indexLoader)
        self.runtimeUsage = runtimeUsage ?? RuntimeUsageService(runner: runner)
        self.uninstaller = RuntimeUninstaller(runner: runner)
        self.remounter = remounter ?? RuntimeRemounter(runner: runner)
        self.terminal = terminal
        self.locale = locale
        self.now = now
    }

    /// - Parameter unusedForDays: Also offer runtimes not used for this many days; `nil` offers
    ///   superseded builds only.
    func run(unusedForDays: Int?, assumeYes: Bool, dryRun: Bool) async throws {
        async let stages = ReleaseStageLookup.load(from: availableRuntimes, timeout: .seconds(10))
        async let usage = runtimeUsage.usage()
        let installed = try await installedRuntimes.installedRuntimes()

        let describer = RuntimeDescriber(stages: await stages, usage: try await usage)
        guard describer.usage.unreadableXcodes.isEmpty else {
            throw PruneError.xcodesUnreadable(describer.usage.unreadableXcodes.map(\.name))
        }
        let plan = PruneRule(unusedForDays: unusedForDays, now: now)
            .plan(for: installed, stages: describer.stages, usage: describer.usage)
        let notes = notes(on: plan, describer: describer)

        guard !plan.candidates.isEmpty else {
            terminal.write((["Nothing to prune."] + notes).joined(separator: "\n"))
            return
        }

        let table = PruneTable(candidates: plan.candidates, describer: describer, numbered: !(dryRun || assumeYes), now: now, locale: locale)
        let runtimes = plan.candidates.map(\.runtime)
        let removal = RuntimeRemoval(uninstaller: uninstaller, remounter: remounter, terminal: terminal, describer: describer, locale: locale)

        if dryRun || assumeYes {
            terminal.write(([table.render()] + notes).joined(separator: "\n\n"))
        }
        if dryRun {
            let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
            terminal.write("Would uninstall \(count), freeing \(removal.totalSize(of: runtimes)).")
            return
        }

        let selected = assumeYes ? runtimes : try pick(from: runtimes, table: table, notes: notes)
        guard !selected.isEmpty else {
            terminal.write("Nothing selected.")
            return
        }
        guard try removal.confirm(selected, assumeYes: assumeYes) else {
            terminal.write("Cancelled. Nothing was uninstalled.")
            return
        }
        try await removal.uninstall(selected)
    }

    private func pick(from runtimes: [InstalledRuntime], table: PruneTable, notes: [String]) throws -> [InstalledRuntime] {
        guard terminal.isInteractive else { throw PruneError.selectionRequired }
        return NumberedPicker(terminal: terminal).pick(
            runtimes,
            table: ([table.render()] + notes).joined(separator: "\n\n"),
            prompt: "Select runtimes to prune",
            emptyMeansAll: true
        )
    }

    /// Lines about runtimes prune leaves alone despite a reason to remove them.
    private func notes(on plan: PrunePlan, describer: RuntimeDescriber) -> [String] {
        let table = PruneTable(candidates: [], describer: describer, now: now, locale: locale)
        let kept = plan.keptInUse.map {
            let xcodes = describer.usage.xcodes(using: $0.runtime).map(\.name).joined(separator: ", ")
            return "Kept \(describer.describe($0.runtime)): \(table.reason($0.reason)), but used by \(xcodes)."
        }
        let undecided = plan.undecided.map { group in
            "Skipped \(describer.name(of: group[0])) (\(group.map(\.build).joined(separator: ", "))): "
                + "Apple's index doesn't list every build, so it's unclear which is newest."
        }
        return kept + undecided
    }
}
