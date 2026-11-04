import Foundation
import Testing
import SimulatorsKit

@Suite("Installed Xcodes")
struct InstalledXcodeServiceTests {
    @Test("Finds Xcodes with Spotlight and the selected one, oldest first, skipping the Trash")
    func findsXcodes() async throws {
        let runner = SequencedCommandRunner(outputs: [
            ["/usr/bin/mdfind", "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"]: [Data("""
                /Applications/Xcode-27.2.0.app
                /Users/me/.Trash/Xcode-26.0.app
                /Applications/Xcode-26.4.app
                """.utf8)],
            ["/usr/bin/xcode-select", "-p"]: [Data("/Volumes/Tools/Xcode-beta.app/Contents/Developer\n".utf8)],
        ])
        let versions = [
            "/Applications/Xcode-27.2.0.app": ("27.2", "27B52"),
            "/Applications/Xcode-26.4.app": ("26.4", "26E101"),
            "/Volumes/Tools/Xcode-beta.app": ("27.3", "27C5021e"),
        ]
        let sut = InstalledXcodeService(runner: runner) { path in
            let app = path.replacingOccurrences(of: "/Contents/version.plist", with: "")
            guard let (version, build) = versions[app] else { throw CocoaError(.fileNoSuchFile) }
            return try PropertyListEncoder().encode(["CFBundleShortVersionString": version, "ProductBuildVersion": build])
        }

        let xcodes = try await sut.installedXcodes()

        #expect(xcodes.map(\.name) == ["Xcode 26.4", "Xcode 27.2", "Xcode 27.3"])
        #expect(xcodes.last?.developerDirectory == "/Volumes/Tools/Xcode-beta.app/Contents/Developer")
    }

    @Test("Ignores Command Line Tools selected instead of an Xcode")
    func ignoresCommandLineTools() async throws {
        let runner = SequencedCommandRunner(outputs: [
            ["/usr/bin/xcode-select", "-p"]: [Data("/Library/Developer/CommandLineTools\n".utf8)],
        ])
        let sut = InstalledXcodeService(runner: runner) { _ in throw CocoaError(.fileNoSuchFile) }

        #expect(try await sut.installedXcodes().isEmpty)
    }
}
