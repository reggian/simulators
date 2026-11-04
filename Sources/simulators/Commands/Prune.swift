import ArgumentParser

struct Prune: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Uninstall superseded runtimes and runtimes not used for a while.",
        discussion: """
            A runtime is superseded when a newer build of the same OS version is installed, for \
            example a beta after the release. Runtimes an installed Xcode uses are kept. Shows the \
            candidates as a numbered list (all by default), then asks before uninstalling.
            """
    )

    @Option(name: .customLong("unused-for"), help: ArgumentHelp("Also offer runtimes not used for this many days.", valueName: "days"))
    var unusedForDays = 180

    @Flag(help: "Only offer superseded builds, not runtimes that haven't been used for a while.")
    var supersededOnly = false

    @Flag(name: .shortAndLong, help: "Uninstall all candidates without asking.")
    var yes = false

    @Flag(help: "Show the candidates without uninstalling anything.")
    var dryRun = false

    func validate() throws {
        guard unusedForDays > 0 else {
            throw ValidationError("--unused-for needs a number of days above zero.")
        }
    }

    func run() async throws {
        try await PruneFlow(terminal: StandardTerminal())
            .run(unusedForDays: supersededOnly ? nil : unusedForDays, assumeYes: yes, dryRun: dryRun)
    }
}
