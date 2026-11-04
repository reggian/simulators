import Foundation

/// Reads the simulator runtimes Apple offers for download.
public struct AvailableRuntimeService: Sendable {
    private let loader: any RuntimeIndexLoader

    public init(loader: any RuntimeIndexLoader = AppleRuntimeIndexLoader()) {
        self.loader = loader
    }

    /// Every current-format runtime in Apple's index, one per platform and build, in listing order
    /// (see ``AvailableRuntime/isOrderedBefore(_:_:)``). Older formats need an Apple account to
    /// download and are left out.
    public func availableRuntimes() async throws -> [AvailableRuntime] {
        let data = try await loader.loadIndex()
        let index = try PropertyListDecoder().decode(RuntimeIndex.self, from: data)

        let entries = index.downloadables.compactMap(\.entry).filter(\.isCurrentFormat)
        let byBuild = Dictionary(grouping: entries) { BuildKey(platform: $0.platform, build: $0.simulatorVersion.buildUpdate) }

        return byBuild.values
            .map(Self.runtime(from:))
            .sorted(by: AvailableRuntime.isOrderedBefore)
    }

    /// Combines the entries for one build, one per architecture variant.
    private static func runtime(from entries: [RuntimeIndexEntry]) -> AvailableRuntime {
        let first = entries[0]
        return AvailableRuntime(
            platform: SimulatorPlatform(indexPlatform: first.platform),
            version: first.simulatorVersion.version,
            build: first.simulatorVersion.buildUpdate,
            stage: ReleaseStage(name: first.name),
            downloads: entries.map {
                RuntimeDownload(variant: ArchitectureVariant(architectures: $0.architectures), sizeBytes: $0.fileSize)
            }
        )
    }
}

private struct BuildKey: Hashable {
    let platform: String
    let build: String
}

private struct RuntimeIndex: Decodable {
    let downloadables: [SkippingInvalid]
}

/// An index entry, or `nil` when it can't be decoded, so one odd entry doesn't hide the rest.
private struct SkippingInvalid: Decodable {
    let entry: RuntimeIndexEntry?

    init(from decoder: any Decoder) throws {
        entry = try? RuntimeIndexEntry(from: decoder)
    }
}
