import ArgumentParser
import SimulatorsKit

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List installed simulator runtimes, or the ones Apple offers for download."
    )

    @Flag(help: "List the runtimes Apple offers for download: per version, the release, or the newest beta.")
    var available = false

    @Flag(help: "With --available, include every beta, release candidate and superseded build.")
    var all = false

    func validate() throws {
        if all && !available {
            throw ValidationError("--all only works together with --available.")
        }
    }

    func run() async throws {
        let installed = try await InstalledRuntimeService().installedRuntimes()
        if available {
            try await listAvailable(installed: installed)
        } else if installed.isEmpty {
            print("No simulator runtimes installed.")
        } else {
            print(RuntimeTable(runtimes: installed).render())
        }
    }

    private func listAvailable(installed: [InstalledRuntime]) async throws {
        let everything = try await AvailableRuntimeService().availableRuntimes()
        let runtimes = all ? everything : everything.current()
        print(AvailableRuntimeTable(runtimes: runtimes, installed: installed).render())
    }
}
