import Foundation
import SimulatorsKit

/// Works out which runtimes to uninstall (from arguments or by asking), confirms, and deletes them.
struct UninstallFlow {
    private let installedRuntimes: InstalledRuntimeService
    private let availableRuntimes: AvailableRuntimeService
    private let runtimeUsage: RuntimeUsageService
    private let uninstaller: RuntimeUninstaller
    private let remounter: RuntimeRemounter
    private let terminal: any Terminal
    private let locale: Locale
    /// Names runtimes with beta labels and the Xcodes that use them; knows neither until
    /// ``run(queries:assumeYes:dryRun:)`` loads them.
    private var describer = RuntimeDescriber()

    /// - Parameters:
    ///   - indexLoader: Apple's runtime index, only used to label betas and RCs.
    ///   - runtimeUsage: Reads which Xcodes use which runtime. Defaults to one using `runner`.
    ///   - remounter: Brings back runtimes whose files `simctl` kept. Defaults to one using `runner`.
    init(
        runner: any CommandRunner = ProcessCommandRunner(),
        indexLoader: any RuntimeIndexLoader = AppleRuntimeIndexLoader(),
        runtimeUsage: RuntimeUsageService? = nil,
        remounter: RuntimeRemounter? = nil,
        terminal: any Terminal,
        locale: Locale = .current
    ) {
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.availableRuntimes = AvailableRuntimeService(loader: indexLoader)
        self.runtimeUsage = runtimeUsage ?? RuntimeUsageService(runner: runner)
        self.uninstaller = RuntimeUninstaller(runner: runner)
        self.remounter = remounter ?? RuntimeRemounter(runner: runner)
        self.terminal = terminal
        self.locale = locale
    }

    func run(queries: [String], assumeYes: Bool, dryRun: Bool) async throws {
        async let stages = ReleaseStageLookup.load(from: availableRuntimes, timeout: .seconds(3))
        async let usage = (try? await runtimeUsage.usage()) ?? .empty
        let runtimes = try await installedRuntimes.installedRuntimes()

        var labelled = self
        labelled.describer = RuntimeDescriber(stages: await stages, usage: await usage)
        try await labelled.run(queries: queries, in: runtimes, assumeYes: assumeYes, dryRun: dryRun)
    }

    private func run(queries: [String], in runtimes: [InstalledRuntime], assumeYes: Bool, dryRun: Bool) async throws {
        let selected = queries.isEmpty
            ? try pick(from: runtimes.filter(\.isDeletable), prompt: "Select runtimes to uninstall")
            : try resolve(queries, in: runtimes)

        guard !selected.isEmpty else {
            terminal.write("Nothing selected.")
            return
        }

        if dryRun {
            selected.forEach { terminal.write("Would uninstall \(describer.describe($0))\(describer.usedBy($0))") }
            return
        }

        let removal = RuntimeRemoval(
            uninstaller: uninstaller,
            remounter: remounter,
            terminal: terminal,
            describer: describer,
            locale: locale
        )
        guard try removal.confirm(selected, assumeYes: assumeYes) else {
            terminal.write("Cancelled. Nothing was uninstalled.")
            return
        }
        try await removal.uninstall(selected)
    }

    // MARK: Choosing runtimes

    private func resolve(_ queries: [String], in runtimes: [InstalledRuntime]) throws -> [InstalledRuntime] {
        var selected: [InstalledRuntime] = []
        for query in queries {
            let matches = runtimes.filter { $0.matches(query) }
            switch matches.count {
            case 0:
                throw UninstallError.noMatch(query)
            case 1:
                selected += matches
            default:
                guard terminal.isInteractive else {
                    throw UninstallError.ambiguous(query, matches: matches.map(describer.describe))
                }
                selected += try pick(from: matches, prompt: "\"\(query)\" matches several runtimes. Select")
            }
        }

        if let undeletable = selected.first(where: { !$0.isDeletable }) {
            throw UninstallError.notDeletable(describer.name(of: undeletable))
        }
        return selected.uniqued()
    }

    /// Shows `candidates` as a numbered table and asks until the input is valid. Empty input or
    /// end of input selects nothing.
    private func pick(from candidates: [InstalledRuntime], prompt: String) throws -> [InstalledRuntime] {
        guard terminal.isInteractive else { throw UninstallError.runtimeArgumentRequired }
        guard !candidates.isEmpty else {
            terminal.write("No runtimes can be uninstalled.")
            return []
        }

        let table = RuntimeTable(runtimes: candidates, stages: describer.stages, usage: describer.usage, numbered: true, locale: locale).render()
        return NumberedPicker(terminal: terminal).pick(candidates, table: table, prompt: prompt)
    }
}

private extension Array where Element == InstalledRuntime {
    /// Removes repeats (the same runtime named twice), keeping the first occurrence.
    func uniqued() -> [InstalledRuntime] {
        var seen = Set<String>()
        return filter { seen.insert($0.identifier).inserted }
    }
}
