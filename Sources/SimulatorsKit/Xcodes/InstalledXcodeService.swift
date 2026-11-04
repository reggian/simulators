import Foundation

/// Finds the Xcodes installed on this Mac: the ones Spotlight knows, plus the selected one
/// (`xcode-select -p`) in case Spotlight doesn't index its location.
public struct InstalledXcodeService: Sendable {
    private let runner: any CommandRunner
    private let readFile: @Sendable (String) throws -> Data

    /// - Parameter readFile: Reads a file's contents; injectable for tests.
    public init(
        runner: any CommandRunner = ProcessCommandRunner(),
        readFile: @escaping @Sendable (String) throws -> Data = { try Data(contentsOf: URL(fileURLWithPath: $0)) }
    ) {
        self.runner = runner
        self.readFile = readFile
    }

    /// Installed Xcodes, oldest version first. Skips apps in the Trash and apps whose version
    /// can't be read.
    public func installedXcodes() async throws -> [InstalledXcode] {
        let spotlight = try await runner.run("/usr/bin/mdfind", ["kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"])
        let selected = try? await runner.run("/usr/bin/xcode-select", ["-p"])

        var paths = lines(of: spotlight)
        if let developerDirectory = selected.flatMap({ lines(of: $0).first }),
           developerDirectory.hasSuffix(".app/Contents/Developer") {
            paths.append(String(developerDirectory.dropLast("/Contents/Developer".count)))
        }

        var seen = Set<String>()
        return paths
            .filter { !$0.contains("/.Trash/") && seen.insert($0).inserted }
            .compactMap(xcode(at:))
            .sorted { ($0.version.numericallyPrecedes($1.version) ?? $0.build.numericallyPrecedes($1.build)) ?? false }
    }

    private func xcode(at path: String) -> InstalledXcode? {
        guard let data = try? readFile(path + "/Contents/version.plist"),
              let version = try? PropertyListDecoder().decode(VersionPlist.self, from: data)
        else { return nil }
        return InstalledXcode(path: path, version: version.CFBundleShortVersionString, build: version.ProductBuildVersion)
    }

    private func lines(of output: Data) -> [String] {
        String(decoding: output, as: UTF8.self).split(separator: "\n").map(String.init)
    }
}

/// The parts of `Xcode.app/Contents/version.plist` the tool reads.
private struct VersionPlist: Decodable {
    let CFBundleShortVersionString: String
    let ProductBuildVersion: String
}
