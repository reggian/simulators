import Foundation
import SimulatorsKit

/// Works out which runtimes to install (from arguments or by asking), confirms, and downloads them
/// one after another with `xcodebuild`.
struct InstallFlow {
    private let availableRuntimes: AvailableRuntimeService
    private let installedRuntimes: InstalledRuntimeService
    private let installer: RuntimeInstaller
    private let terminal: any Terminal
    private let locale: Locale

    init(
        runner: any CommandRunner = ProcessCommandRunner(),
        indexLoader: any RuntimeIndexLoader = AppleRuntimeIndexLoader(),
        terminal: any Terminal,
        locale: Locale = .current
    ) {
        self.availableRuntimes = AvailableRuntimeService(loader: indexLoader)
        self.installedRuntimes = InstalledRuntimeService(runner: runner)
        self.installer = RuntimeInstaller(runner: runner)
        self.terminal = terminal
        self.locale = locale
    }

    /// - Parameter variant: The architecture variant to install; `nil` picks arm64 when offered.
    func run(arguments: [String], variant: ArchitectureVariant?, assumeYes: Bool, dryRun: Bool) async throws {
        let available = try await availableRuntimes.availableRuntimes()
        let installed = try await installedRuntimes.installedRuntimes()

        let selected = arguments.isEmpty
            ? try pickNotInstalled(from: available.current(), installed: installed)
            : try resolve(RuntimeQuery.parse(arguments), in: available, installed: installed)

        let alreadyInstalled = selected.filter { $0.isInstalled(in: installed) }
        alreadyInstalled.forEach { terminal.write("\(describe($0)) is already installed.") }

        let downloads = try selected
            .filter { !$0.isInstalled(in: installed) }
            .map { ($0, try download(of: $0, variant: variant)) }
        guard !downloads.isEmpty else {
            if alreadyInstalled.isEmpty { terminal.write("Nothing selected.") }
            return
        }

        // A dry run in a terminal rehearses the whole flow; without one (or with --yes) it reports.
        if dryRun && (assumeYes || !terminal.isInteractive) {
            downloads.forEach { terminal.write("Would install \(describe($0.0, $0.1))") }
            return
        }

        guard try confirm(downloads, assumeYes: assumeYes, dryRun: dryRun) else {
            terminal.write("Cancelled. Nothing was installed.")
            return
        }
        guard !dryRun else {
            terminal.write("Dry run: nothing was installed.")
            return
        }
        try await install(downloads)
    }

    // MARK: Confirming

    /// Lists the downloads and asks y/N, unless `assumeYes`. In a dry run, the question says so.
    private func confirm(_ downloads: [(AvailableRuntime, RuntimeDownload)], assumeYes: Bool, dryRun: Bool) throws -> Bool {
        if assumeYes { return true }
        guard terminal.isInteractive else { throw InstallError.confirmationRequired }

        terminal.write("About to install:")
        downloads.forEach { terminal.write("  \(describe($0.0, $0.1))") }
        let count = downloads.count == 1 ? "1 runtime" : "\(downloads.count) runtimes"
        let size = downloads.map(\.1.sizeBytes).reduce(0, +).fileSize(locale: locale)
        return terminal.askYesNo("Install \(count), downloading \(size)\(dryRun ? " (dry run)" : "")?")
    }

    // MARK: Installing

    /// Installs each runtime in turn, carrying on past failures, and throws at the end if any failed.
    private func install(_ downloads: [(AvailableRuntime, RuntimeDownload)]) async throws {
        var failed: [String] = []
        for (runtime, download) in downloads {
            terminal.write("Installing \(describe(runtime, download))…")
            do {
                try await installer.install(runtime, variant: download.variant)
            } catch {
                terminal.write("  \(error.localizedDescription)")
                failed.append(describe(runtime))
            }
        }

        guard failed.isEmpty else { throw InstallError.incomplete(failed: failed) }
        terminal.write("Done.")
    }

    private func download(of runtime: AvailableRuntime, variant: ArchitectureVariant?) throws -> RuntimeDownload {
        guard let variant else { return runtime.defaultDownload }
        guard let download = runtime.download(for: variant) else {
            throw InstallError.variantUnavailable(
                describe(runtime),
                requested: variant.rawValue,
                offered: runtime.downloads.map(\.variant.rawValue)
            )
        }
        return download
    }

    // MARK: Choosing runtimes

    private func pickNotInstalled(
        from candidates: [AvailableRuntime],
        installed: [InstalledRuntime]
    ) throws -> [AvailableRuntime] {
        guard terminal.isInteractive else { throw InstallError.runtimeArgumentRequired }
        let notInstalled = candidates.filter { !$0.isInstalled(in: installed) }
        guard !notInstalled.isEmpty else {
            terminal.write("All current runtimes are installed. Run `simulators list --available --all` for others.")
            return []
        }
        var table = AvailableRuntimeTable(runtimes: notInstalled, numbered: true, styler: terminal.styler, locale: locale).render()
        let hidden = candidates.count - notInstalled.count
        if hidden > 0 {
            table += "\n\n" + (hidden == 1 ? "1 installed runtime isn't shown." : "\(hidden) installed runtimes aren't shown.")
        }
        return NumberedPicker(terminal: terminal).pick(notInstalled, table: table, prompt: "Select runtimes to install")
    }

    private func resolve(
        _ queries: [RuntimeQuery],
        in available: [AvailableRuntime],
        installed: [InstalledRuntime]
    ) throws -> [AvailableRuntime] {
        var selected: [AvailableRuntime] = []
        for query in queries {
            let matches = query.matches(in: available)
            switch matches.count {
            case 0:
                throw InstallError.noMatch(query.description)
            case 1:
                selected += matches
            default:
                guard terminal.isInteractive else {
                    throw InstallError.ambiguous(query.description, matches: matches.map(describe))
                }
                let table = AvailableRuntimeTable(runtimes: matches, installed: installed, numbered: true, styler: terminal.styler, locale: locale).render()
                selected += NumberedPicker(terminal: terminal)
                    .pick(matches, table: table, prompt: "\"\(query.description)\" matches several runtimes. Select")
            }
        }
        return selected.uniqued()
    }

    // MARK: Text

    private func describe(_ runtime: AvailableRuntime) -> String {
        "\(runtime.name) (\(runtime.build))"
    }

    private func describe(_ runtime: AvailableRuntime, _ download: RuntimeDownload) -> String {
        "\(runtime.name) (\(runtime.build), \(download.variant.rawValue), \(download.sizeBytes.fileSize(locale: locale)))"
    }
}

private extension Array where Element == AvailableRuntime {
    /// Removes repeats (the same runtime asked for twice), keeping the first occurrence.
    func uniqued() -> [AvailableRuntime] {
        var seen = Set<String>()
        return filter { seen.insert("\($0.platform.identifier) \($0.build)").inserted }
    }
}
