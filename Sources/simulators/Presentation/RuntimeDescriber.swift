import SimulatorsKit

/// Names installed runtimes in messages: with beta and RC labels, and the Xcodes that use them.
struct RuntimeDescriber {
    var stages: ReleaseStageLookup = .empty
    var usage: RuntimeUsage = .empty

    /// For example `iOS 27.3 beta` or `iOS 27.2 (iPhone19-4)`.
    func name(of runtime: InstalledRuntime) -> String {
        runtime.name(stage: stages.stage(of: runtime))
    }

    /// The name and build, for example `iOS 27.3 beta (24C5037i)`.
    func describe(_ runtime: InstalledRuntime) -> String {
        "\(name(of: runtime)) (\(runtime.build))"
    }

    /// `, used by Xcode 27.2`, or nothing when no installed Xcode uses `runtime`.
    func usedBy(_ runtime: InstalledRuntime) -> String {
        let xcodes = usage.xcodes(using: runtime)
        return xcodes.isEmpty ? "" : ", used by " + xcodes.map(\.name).joined(separator: ", ")
    }
}
