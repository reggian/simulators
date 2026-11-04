import Foundation
import SimulatorsKit

/// Confirms and uninstalls runtimes the user chose. Shared by `uninstall` and `prune`.
struct RuntimeRemoval {
    let uninstaller: RuntimeUninstaller
    let remounter: RuntimeRemounter
    let terminal: any Terminal
    let describer: RuntimeDescriber
    let locale: Locale

    // MARK: Confirming

    /// Lists `runtimes` with the Xcodes that use them and asks y/N, unless `assumeYes`.
    ///
    /// - Throws: ``UninstallError/confirmationRequired`` when there's no terminal to ask.
    func confirm(_ runtimes: [InstalledRuntime], assumeYes: Bool) throws -> Bool {
        if assumeYes { return true }
        guard terminal.isInteractive else { throw UninstallError.confirmationRequired }

        terminal.write("About to uninstall:")
        runtimes.forEach { terminal.write("  \(describer.describe($0))\(describer.usedBy($0))") }
        if runtimes.contains(where: { !describer.usage.xcodes(using: $0).isEmpty }) {
            terminal.write("Xcode uses these runtimes to build, preview and run simulators of that OS version.")
        }
        let count = runtimes.count == 1 ? "1 runtime" : "\(runtimes.count) runtimes"
        return terminal.askYesNo("Uninstall \(count), freeing \(totalSize(of: runtimes))?")
    }

    // MARK: Uninstalling

    /// Uninstalls each runtime in turn, carrying on past failures, and throws at the end if any failed.
    func uninstall(_ runtimes: [InstalledRuntime]) async throws {
        var freed: [InstalledRuntime] = []
        var failed: [String] = []
        for runtime in runtimes {
            terminal.write("Uninstalling \(describer.describe(runtime))…")
            do {
                try await uninstallReclaimingFiles(runtime)
                freed.append(runtime)
            } catch let kept as RuntimeAssetKept {
                terminal.write(describe(kept, of: runtime))
                failed.append(describer.describe(runtime))
            } catch {
                terminal.write("  \(error.localizedDescription)")
                failed.append(describer.describe(runtime))
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
            terminal.write("  simctl left its files behind. Waiting for macOS to register \(describer.name(of: runtime)) again…")
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
            + "`xcrun simctl runtime scan-and-mount`, wait until \(describer.name(of: runtime)) is back in "
            + "`simulators list` (it can take a while), and uninstall it again."
    }

    /// The total size of `runtimes`, for example `15,7 GB`.
    func totalSize(of runtimes: [InstalledRuntime]) -> String {
        Int64.totalSize(of: runtimes.map(\.sizeBytes)).fileSize(locale: locale)
    }
}
