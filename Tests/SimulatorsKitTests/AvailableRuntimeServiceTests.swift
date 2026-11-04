import Foundation
import Testing
import SimulatorsKit

@Suite("Available runtimes")
struct AvailableRuntimeServiceTests {
    @Test("Reads current-format runtimes from Apple's index, one per build, in listing order")
    func readsIndex() async throws {
        let sut = AvailableRuntimeService(loader: try StubIndexLoader.fixture())

        let runtimes = try await sut.availableRuntimes()

        // The fixture also holds a tvOS 16 disk image and an iOS 12.4 package, which need an
        // Apple account and are left out.
        #expect(runtimes.map(\.name) == [
            "iOS 18.6", "iOS 26.5", "iOS 27.1 RC", "iOS 27.1", "iOS 27.2 beta 4", "iOS 27.2", "iOS 27.2",
            "iOS 27.3 beta", "watchOS 27.2",
        ])
        #expect(runtimes.map(\.build) == [
            "22G86", "23F77", "24A94232", "24A94425", "24B5110a", "24B8117", "24B91016s", "24C5037i", "24S118",
        ])
    }

    @Test("Combines a build's architecture variants, arm64 first")
    func combinesVariants() async throws {
        let runtimes = try await AvailableRuntimeService(loader: try StubIndexLoader.fixture()).availableRuntimes()

        let both = try #require(runtimes.first { $0.build == "23F77" })
        #expect(both.downloads == [
            RuntimeDownload(variant: .arm64, sizeBytes: 8_522_901_969),
            RuntimeDownload(variant: .universal, sizeBytes: 10_603_484_383),
        ])
        // Older entries list no architectures; they're universal.
        let old = try #require(runtimes.first { $0.build == "22G86" })
        #expect(old.downloads.map(\.variant) == [.universal])
    }
}

@Suite("Current available runtimes")
struct CurrentAvailableRuntimeTests {
    @Test("Keeps release builds per version, or the newest pre-release when there's no release")
    func keepsReleasesOrNewestPrerelease() async throws {
        let runtimes = try await AvailableRuntimeService(loader: try StubIndexLoader.fixture()).availableRuntimes()

        let current = runtimes.current()

        #expect(current.map(\.build) == [
            "22G86", "23F77", "24A94425", "24B8117", "24B91016s", "24C5037i", "24S118",
        ])
    }
}
