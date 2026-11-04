import Foundation
import SimulatorsKit

/// Works out which runtimes to uninstall (from arguments or by asking), confirms, and deletes them.
struct UninstallFlow {
    private let installedRuntimes: InstalledRuntimeService
    private let availableRuntimes: AvailableRuntimeService
    private let uninstaller: RuntimeUninstaller
    private let remounter: RuntimeRemounter
    private let terminal: any Terminal
    private let locale: Locale
    /// Beta and RC labels for names; empty until ``run(queries:assumeYes:dryRun:)`` loads them.
    private var stages = ReleaseStageLookup.empty

    /// - Parameters:
    ///   - indexLoader: Apple's runtime index, only used to label betas and RCs.
    ///   - remounter: Brings back runtimes whose files `simctl` kept. Defaults to one using `runner`.
    init(
        runner: any CommandRunner = ProcessCommandRunner(),
        indexLoader: any RuntimeIndexLoader = AppleRuntimeIndexLoader(),
        remounter: RuntimeRemounter? = nil,
        terminal: any Terminal,
        locale: Locale = .current
    ) {
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.availableRuntimes = AvailableRuntimeService(loader: indexLoader)
        self.uninstaller = RuntimeUninstaller(runner: runner)
        self.remounter = remounter ?? RuntimeRemounter(runner: runner)
        self.terminal = terminal
        self.locale = locale
    }

    func run(queries: [String], assumeYes: Bool, dryRun: Bool) async throws {
        async let stages = ReleaseStageLookup.load(from: availableRuntimes, timeout: .seconds(3))
        let runtimes = try await installedRuntimes.installedRuntimes()

        var labelled = self
        labelled.stages = await stages
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
            selected.forEach { terminal.write("Would uninstall \(describe($0))") }
            return
        }

        guard try confirm(selected, assumeYes: assumeYes) else {
            terminal.write("Cancelled. Nothing was uninstalled.")
            return
        }

        try await uninstall(selected)
    }

    // MARK: Uninstalling

    /// Uninstalls each runtime in turn, carrying on past failures, and throws at the end if any failed.
    private func uninstall(_ runtimes: [InstalledRuntime]) async throws {
        var freed: [InstalledRuntime] = []
        var failed: [String] = []
        for runtime in runtimes {
            terminal.write("Uninstalling \(describe(runtime))…")
            do {
                try await uninstallReclaimingFiles(runtime)
                freed.append(runtime)
            } catch let kept as RuntimeAssetKept {
                terminal.write(describe(kept, of: runtime))
                failed.append(describe(runtime))
            } catch {
                terminal.write("  \(error.localizedDescription)")
                failed.append(describe(runtime))
            }
        }

        guard failed.isEmpty else {
            throw UninstallError.incomplete(failed: failed, freed: freed.isEmpty ? nil : totalSize(of: freed))
        }
        terminal.write("Done. Freed \(totalSize(of: freed)).")
    }

    /// Uninstalls `runtime`. When `simctl` unregisters it but keeps its files, waits for it to be
    /// registered again and deletes it once more, which removes the files.
    ///
    /// - Throws: ``RuntimeAssetKept`` when the files are still there after that.
    private func uninstallReclaimingFiles(_ runtime: InstalledRuntime) async throws {
        do {
            try await uninstaller.uninstall(runtime)
        } catch let kept as RuntimeAssetKept {
            terminal.write("  simctl left its files behind. Waiting for macOS to register \(name(of: runtime)) again…")
            guard let remounted = try await remounter.remount(runtime) else {
                terminal.write("  It isn't back yet.")
                throw kept
            }
            terminal.write("  Uninstalling it again…")
            try await uninstaller.uninstall(remounted)
        }
    }

    private func describe(_ kept: RuntimeAssetKept, of runtime: InstalledRuntime) -> String {
        let size = runtime.sizeBytes.map { " (\($0.fileSize(locale: locale)))" } ?? ""
        let location = kept.assetPath.map { " in \($0)" } ?? ""
        return "  Its files\(size) are still\(location). To free them, run "
            + "`xcrun simctl runtime scan-and-mount`, wait until \(name(of: runtime)) is back in "
            + "`simulators list` (it can take a while), and uninstall it again."
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
                    throw UninstallError.ambiguous(query, matches: matches.map(describe))
                }
                selected += try pick(from: matches, prompt: "\"\(query)\" matches several runtimes. Select")
            }
        }

        if let undeletable = selected.first(where: { !$0.isDeletable }) {
            throw UninstallError.notDeletable(name(of: undeletable))
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

        let table = RuntimeTable(runtimes: candidates, stages: stages, numbered: true, locale: locale).render()
        return NumberedPicker(terminal: terminal).pick(candidates, table: table, prompt: prompt)
    }

    // MARK: Confirming

    private func confirm(_ runtimes: [InstalledRuntime], assumeYes: Bool) throws -> Bool {
        if assumeYes { return true }
        guard terminal.isInteractive else { throw UninstallError.confirmationRequired }

        terminal.write("About to uninstall:")
        runtimes.forEach { terminal.write("  \(describe($0))") }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return terminal.askYesNo("Uninstall \(count), freeing \(totalSize(of: runtimes))?")
    }

    // MARK: Text

    private func describe(_ runtime: InstalledRuntime) -> String {
        "\(name(of: runtime)) (\(runtime.build))"
    }

    private func name(of runtime: InstalledRuntime) -> String {
        runtime.name(stage: stages.stage(of: runtime))
    }

    private func totalSize(of runtimes: [InstalledRuntime]) -> String {
        Int64.totalSize(of: runtimes.map(\.sizeBytes)).fileSize(locale: locale)
    }
}

private extension Array where Element == InstalledRuntime {
    /// Removes repeats (the same runtime named twice), keeping the first occurrence.
    func uniqued() -> [InstalledRuntime] {
        var seen = Set<String>()
        return filter { seen.insert($0.identifier).inserted }
    }
}
