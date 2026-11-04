import Foundation
import Testing
import SimulatorsKit
@testable import simulators

@Suite("Available runtime table")
struct AvailableRuntimeTableTests {
    @Test("Shows variants, the default download's size and which runtimes are installed")
    func rendersRuntimes() {
        let ios = SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator")
        let sut = AvailableRuntimeTable(
            runtimes: [
                AvailableRuntime(platform: ios, version: "26.5", build: "23F77", stage: .release, downloads: [
                    RuntimeDownload(variant: .universal, sizeBytes: 10_603_484_383),
                    RuntimeDownload(variant: .arm64, sizeBytes: 8_522_901_969),
                ]),
                AvailableRuntime(platform: ios, version: "27.3", build: "24C5037i", stage: .beta(nil), downloads: [
                    RuntimeDownload(variant: .arm64, sizeBytes: 8_520_000_000),
                ]),
            ],
            installed: [
                InstalledRuntime(identifier: "A", runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-26-5",
                                 platform: ios, version: "26.5", build: "23F77", architectures: ["arm64"],
                                 sizeBytes: nil, lastUsedAt: nil),
            ],
            locale: Locale(identifier: "en_US_POSIX")
        )

        #expect(sut.render() == """
        Runtime        Build     Arch              Size     Installed
        iOS 26.5       23F77     arm64, universal  8.52 GB  yes
        iOS 27.3 beta  24C5037i  arm64             8.52 GB

        2 runtimes
        """)
    }
}
