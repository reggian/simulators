import ArgumentParser
import SimulatorsKit

struct Install: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Download and install simulator runtimes.",
        discussion: """
            Without arguments, shows the current runtimes you don't have yet as a numbered list to \
            pick from. Asks before downloading, with the total size. Downloads go through \
            xcodebuild, which shows its own progress.
            """
    )

    @Argument(help: """
        Runtimes to install: a platform and version (iOS 27.2), a platform for its newest release \
        (iOS), or a build (24B8117).
        """)
    var runtimes: [String] = []

    @Option(
        name: .customLong("arch"),
        help: "Architecture variant: arm64 or universal. Defaults to arm64 when Apple offers it.",
        transform: { value in
            guard let variant = ArchitectureVariant(rawValue: value) else {
                throw ValidationError("Unknown architecture variant \"\(value)\". Use arm64 or universal.")
            }
            return variant
        }
    )
    var variant: ArchitectureVariant?

    @Flag(name: .shortAndLong, help: "Don't ask for confirmation.")
    var yes = false

    @Flag(help: "Show what would be installed without downloading anything.")
    var dryRun = false

    func run() async throws {
        try await InstallFlow(terminal: StandardTerminal())
            .run(arguments: runtimes, variant: variant, assumeYes: yes, dryRun: dryRun)
    }
}
