import Foundation
import Testing
import SimulatorsKit

@Suite("Release stage lookup")
struct ReleaseStageLookupTests {
    @Test("Labels installed runtimes by platform and build")
    func labelsInstalledRuntimes() async throws {
        let service = AvailableRuntimeService(loader: try StubIndexLoader.fixture())
        let sut = await ReleaseStageLookup.load(from: service, timeout: .seconds(10))

        let beta = installed(build: "24C5037i", version: "27.3")
        #expect(beta.name(stage: sut.stage(of: beta)) == "iOS 27.3 beta")
        #expect(sut.stage(of: installed(build: "24B8117", version: "27.2")) == .release)
        #expect(sut.stage(of: installed(build: "21C62", version: "17.2")) == nil)
    }

    @Test("Names a device-specific beta with both labels")
    func deviceSpecificBeta() {
        let runtime = installed(build: "24B91011", version: "27.2", identifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4")

        #expect(runtime.name(stage: .beta(4)) == "iOS 27.2 beta 4 (iPhone19-4)")
    }

    @Test("Knows no stages when the index fails or is too slow", arguments: [
        StalledIndexLoader() as any RuntimeIndexLoader,
        FailingIndexLoader(),
    ])
    func givesUp(loader: any RuntimeIndexLoader) async {
        let service = AvailableRuntimeService(loader: loader)
        let sut = await ReleaseStageLookup.load(from: service, timeout: .milliseconds(50))

        #expect(sut.stage(of: installed(build: "24C5037i", version: "27.3")) == nil)
    }

    private func installed(
        build: String,
        version: String,
        identifier: String = "com.apple.CoreSimulator.SimRuntime.iOS-27-3"
    ) -> InstalledRuntime {
        InstalledRuntime(
            identifier: build,
            runtimeIdentifier: identifier,
            platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
            version: version,
            build: build,
            architectures: ["arm64"],
            sizeBytes: nil,
            lastUsedAt: nil
        )
    }
}

/// Never answers, like a stalled network request.
private struct StalledIndexLoader: RuntimeIndexLoader {
    func loadIndex() async throws -> Data {
        try await Task.sleep(for: .seconds(60))
        return Data()
    }
}

private struct FailingIndexLoader: RuntimeIndexLoader {
    func loadIndex() async throws -> Data {
        throw URLError(.notConnectedToInternet)
    }
}
