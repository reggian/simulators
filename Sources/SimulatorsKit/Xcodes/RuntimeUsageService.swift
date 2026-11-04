import Foundation

/// Reads which runtime builds each installed Xcode uses.
public struct RuntimeUsageService: Sendable {
    private let runner: any CommandRunner
    private let xcodes: InstalledXcodeService

    /// - Parameter xcodes: Finds the installed Xcodes. Defaults to one using `runner`.
    public init(runner: any CommandRunner = ProcessCommandRunner(), xcodes: InstalledXcodeService? = nil) {
        self.runner = runner
        self.xcodes = xcodes ?? InstalledXcodeService(runner: runner)
    }

    /// Runs `simctl runtime match list` once per installed Xcode, with `DEVELOPER_DIR` pointing at
    /// it, because `simctl` only answers for one Xcode at a time. An Xcode it can't ask is listed
    /// in ``RuntimeUsage/unreadableXcodes``.
    public func usage() async throws -> RuntimeUsage {
        var choices: [(xcode: InstalledXcode, platform: SimulatorPlatform, build: String)] = []
        var unreadable: [InstalledXcode] = []
        for xcode in try await xcodes.installedXcodes() {
            guard let output = try? await runner.run("/usr/bin/env", [
                "DEVELOPER_DIR=\(xcode.developerDirectory)", "/usr/bin/xcrun", "simctl", "runtime", "match", "list", "-j",
            ]),
                let matches = try? JSONDecoder().decode([String: SDKMatch].self, from: output)
            else {
                unreadable.append(xcode)
                continue
            }

            choices += matches.values.map {
                (xcode, SimulatorPlatform(indexPlatform: $0.platform), $0.chosenRuntimeBuild)
            }
        }
        return RuntimeUsage(choices: choices, unreadableXcodes: unreadable)
    }
}

/// One SDK's entry in `simctl runtime match list -j`.
private struct SDKMatch: Decodable {
    /// The SDK's device platform, for example `com.apple.platform.iphoneos`.
    let platform: String
    /// The runtime build Xcode picks for this SDK. It may not be installed.
    let chosenRuntimeBuild: String
}
