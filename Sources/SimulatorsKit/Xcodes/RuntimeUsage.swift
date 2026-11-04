/// Which installed Xcodes use which runtimes.
///
/// An Xcode uses, per SDK, one runtime build for building, SwiftUI previews and running simulators
/// of that OS version (`simctl runtime match list`). Device-specific runtimes such as
/// `iOS-27-2-iPhone19-4` are never that build, so no Xcode shows as using them.
public struct RuntimeUsage: Sendable {
    private let xcodesByRuntime: [Key: [InstalledXcode]]

    /// Usage that knows no Xcodes, for when it can't be read.
    public static let empty = RuntimeUsage(choices: [])

    /// - Parameter choices: Per Xcode and SDK, the platform and runtime build it picks.
    init(choices: [(xcode: InstalledXcode, platform: SimulatorPlatform, build: String)]) {
        var xcodesByRuntime: [Key: [InstalledXcode]] = [:]
        for choice in choices {
            let key = Key(platform: choice.platform, build: choice.build)
            if xcodesByRuntime[key]?.contains(choice.xcode) != true {
                xcodesByRuntime[key, default: []].append(choice.xcode)
            }
        }
        self.xcodesByRuntime = xcodesByRuntime
    }

    /// The Xcodes that use `runtime`, in the order they were read (oldest version first).
    public func xcodes(using runtime: InstalledRuntime) -> [InstalledXcode] {
        xcodesByRuntime[Key(platform: runtime.platform, build: runtime.build)] ?? []
    }

    private struct Key: Hashable {
        let platform: SimulatorPlatform
        let build: String
    }
}
