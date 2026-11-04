import Foundation
import SimulatorsKit

/// Works out which runtimes to uninstall (from arguments or by asking), confirms, and deletes them.
struct UninstallFlow {
    private let installedRuntimes: InstalledRuntimeService
    private let uninstaller: RuntimeUninstaller
    private let terminal: any Terminal
    private let locale: Locale

    init(runner: any CommandRunner = ProcessCommandRunner(), terminal: any Terminal, locale: Locale = .current) {
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.uninstaller = RuntimeUninstaller(runner: runner)
        self.terminal = terminal
        self.locale = locale
    }

    func run(queries: [String], assumeYes: Bool, dryRun: Bool) async throws {
        let runtimes = try await installedRuntimes.installedRuntimes()
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
                try await uninstaller.uninstall(runtime)
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

    private func describe(_ kept: RuntimeAssetKept, of runtime: InstalledRuntime) -> String {
        let size = runtime.sizeBytes.map { " (\($0.fileSize(locale: locale)))" } ?? ""
        let location = kept.assetPath.map { " in \($0)" } ?? ""
        return "  simctl unregistered it but left its files\(size)\(location). To free them, run "
            + "`xcrun simctl runtime scan-and-mount`, wait until \(runtime.name) is back in "
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
            throw UninstallError.notDeletable(undeletable.name)
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

        terminal.write(RuntimeTable(runtimes: candidates, numbered: true, locale: locale).render() + "\n")
        let selection = NumberedSelection(count: candidates.count)
        while let input = terminal.readLine(prompt: "\(prompt) (e.g. 1 3, 2-4, all): ") {
            do {
                return try selection.indices(from: input).map { candidates[$0] }
            } catch {
                terminal.write(error.localizedDescription)
            }
        }
        return []
    }

    // MARK: Confirming

    private func confirm(_ runtimes: [InstalledRuntime], assumeYes: Bool) throws -> Bool {
        if assumeYes { return true }
        guard terminal.isInteractive else { throw UninstallError.confirmationRequired }

        terminal.write("About to uninstall:")
        runtimes.forEach { terminal.write("  \(describe($0))") }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        let answer = terminal.readLine(prompt: "Uninstall \(count), freeing \(totalSize(of: runtimes))? [y/N] ")
        return ["y", "yes"].contains(answer?.trimmingCharacters(in: .whitespaces).lowercased())
    }

    // MARK: Text

    private func describe(_ runtime: InstalledRuntime) -> String {
        "\(runtime.name) (\(runtime.build))"
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
