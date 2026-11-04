import ArgumentParser

struct Uninstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Uninstall simulator runtimes.",
        discussion: "Without arguments, shows the installed runtimes as a numbered list to pick from."
    )

    @Argument(help: "Runtimes to uninstall: a build (24B8117), a name (\"iOS 27.2\") or a UUID.")
    var runtimes: [String] = []

    @Flag(name: .shortAndLong, help: "Don't ask for confirmation.")
    var yes = false

    @Flag(help: "Show what would be uninstalled without deleting anything.")
    var dryRun = false

    func run() async throws {
        try await UninstallFlow(terminal: StandardTerminal())
            .run(queries: runtimes, assumeYes: yes, dryRun: dryRun)
    }
}
