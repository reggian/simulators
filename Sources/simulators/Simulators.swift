import ArgumentParser

@main
struct Simulators: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simulators",
        abstract: "Install, list, uninstall and prune Xcode simulator runtimes.",
        subcommands: [List.self, Install.self, Uninstall.self]
    )
}
