import Foundation
import Testing
import SimulatorsKit
@testable import simulators

@Suite("Runtime table")
struct RuntimeTableTests {
    private let now = Date(timeIntervalSince1970: 1_793_000_000) // 2026-10-26, UTC

    @Test("Renders aligned columns and the total size")
    func rendersRuntimes() {
        let sut = makeSUT(runtimes: [
            makeRuntime(version: "17.2", build: "21C62", architectures: ["x86_64", "arm64"], sizeBytes: 7_351_124_481, lastUsedAt: now),
            makeRuntime(runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4", version: "27.2", build: "24B91016s", architectures: ["arm64"], sizeBytes: 8_300_000_000, lastUsedAt: nil),
        ])

        #expect(sut.render() == """
        Runtime                Build      Arch       Size     Last used
        iOS 17.2               21C62      universal  7.35 GB  today
        iOS 27.2 (iPhone19-4)  24B91016s  arm64      8.3 GB   -

        2 runtimes, 15.65 GB
        """)
    }

    @Test("Labels betas and release candidates it knows from Apple's index")
    func labelsStages() {
        let ios = SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator")
        let stages = ReleaseStageLookup(available: [
            AvailableRuntime(platform: ios, version: "27.3", build: "24C5037i", stage: .beta(nil), downloads: [
                RuntimeDownload(variant: .arm64, sizeBytes: 1),
            ]),
        ])
        var sut = makeSUT(runtimes: [
            makeRuntime(version: "17.2", build: "21C62", architectures: ["arm64"], sizeBytes: nil, lastUsedAt: nil),
            makeRuntime(version: "27.3", build: "24C5037i", architectures: ["arm64"], sizeBytes: nil, lastUsedAt: nil),
        ])
        sut.stages = stages

        #expect(sut.render().contains("iOS 17.2       21C62"))
        #expect(sut.render().contains("iOS 27.3 beta  24C5037i"))
    }

    @Test("Describes when a runtime was last used in calendar days", arguments: [
        (nil, "-"),
        (0, "today"),
        (1, "yesterday"),
        (12, "12 days ago"),
    ] as [(Int?, String)])
    func lastUsed(daysAgo: Int?, expected: String) {
        let calendar = utcCalendar
        let sut = LastUsedDescription(now: now, calendar: calendar)
        let lastUsed = daysAgo.flatMap { calendar.date(byAdding: .day, value: -$0, to: now) }

        #expect(sut.describe(lastUsed) == expected)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func makeSUT(runtimes: [InstalledRuntime]) -> RuntimeTable {
        RuntimeTable(runtimes: runtimes, now: now, calendar: utcCalendar, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func makeRuntime(
        runtimeIdentifier: String? = nil,
        version: String,
        build: String,
        architectures: [String],
        sizeBytes: Int64?,
        lastUsedAt: Date?
    ) -> InstalledRuntime {
        InstalledRuntime(
            identifier: UUID().uuidString,
            runtimeIdentifier: runtimeIdentifier ?? "com.apple.CoreSimulator.SimRuntime.iOS-\(version.replacingOccurrences(of: ".", with: "-"))",
            platform: SimulatorPlatform(identifier: "com.apple.platform.iphonesimulator"),
            version: version,
            build: build,
            architectures: architectures,
            sizeBytes: sizeBytes,
            lastUsedAt: lastUsedAt
        )
    }
}
