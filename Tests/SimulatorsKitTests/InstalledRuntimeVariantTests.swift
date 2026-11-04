import Testing
import SimulatorsKit

@Suite("Runtime variant")
struct InstalledRuntimeVariantTests {
    @Test("Reads the device-specific part of the runtime identifier", arguments: [
        ("com.apple.CoreSimulator.SimRuntime.iOS-27-2", nil),
        ("com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4", "iPhone19-4"),
        ("com.apple.CoreSimulator.SimRuntime.xrOS-2-0", nil),
        ("com.apple.CoreSimulator.SimRuntime.watchOS-27-0", nil),
    ] as [(String, String?)])
    func variant(runtimeIdentifier: String, expected: String?) {
        let sut = InstalledRuntime(
            identifier: "A",
            runtimeIdentifier: runtimeIdentifier,
            platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
            version: "27.2",
            build: "24B8117",
            architectures: ["arm64"],
            sizeBytes: nil,
            lastUsedAt: nil
        )

        #expect(sut.variant == expected)
    }
}
