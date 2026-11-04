import ArgumentParser
import SimulatorsKit

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List installed simulator runtimes."
    )

    func run() async throws {
        let runtimes = try await InstalledRuntimeService().installedRuntimes()

        guard !runtimes.isEmpty else {
            print("No simulator runtimes installed.")
            return
        }
        print(RuntimeTable(runtimes: runtimes).render())
    }
}
