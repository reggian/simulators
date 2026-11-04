import Foundation

/// A simulator runtime installed on this Mac, as reported by `xcrun simctl runtime list -j`.
public struct InstalledRuntime: Equatable, Sendable, Decodable {
    /// CoreSimulator's UUID for the runtime image.
    public let identifier: String
    /// For example `com.apple.CoreSimulator.SimRuntime.iOS-27-2`.
    public let runtimeIdentifier: String
    public let platform: SimulatorPlatform
    /// The OS version, for example `27.2`.
    public let version: String
    /// Apple's build number, for example `24B8117`.
    public let build: String
    public let architectures: [String]
    public let sizeBytes: Int64?
    public let lastUsedAt: Date?
    /// Whether `simctl` can delete it. Runtimes bundled inside an Xcode can't be.
    public let isDeletable: Bool
    /// Whether the runtime is mounted and usable (`simctl` reports its state as `Ready`).
    public let isReady: Bool

    public init(
        identifier: String,
        runtimeIdentifier: String,
        platform: SimulatorPlatform,
        version: String,
        build: String,
        architectures: [String],
        sizeBytes: Int64?,
        lastUsedAt: Date?,
        isDeletable: Bool = true,
        isReady: Bool = true
    ) {
        self.identifier = identifier
        self.runtimeIdentifier = runtimeIdentifier
        self.platform = platform
        self.version = version
        self.build = build
        self.architectures = architectures
        self.sizeBytes = sizeBytes
        self.lastUsedAt = lastUsedAt
        self.isDeletable = isDeletable
        self.isReady = isReady
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        runtimeIdentifier = try container.decode(String.self, forKey: .runtimeIdentifier)
        platform = try container.decode(SimulatorPlatform.self, forKey: .platformIdentifier)
        version = try container.decode(String.self, forKey: .version)
        build = try container.decode(String.self, forKey: .build)
        architectures = try container.decodeIfPresent([String].self, forKey: .supportedArchitectures) ?? []
        sizeBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeBytes)
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        // Treat a missing flag as "not deletable": the safe default for a tool that deletes things.
        isDeletable = try container.decodeIfPresent(Bool.self, forKey: .deletable) ?? false
        isReady = try container.decodeIfPresent(String.self, forKey: .state) == "Ready"
    }

    private enum CodingKeys: String, CodingKey {
        case identifier
        case runtimeIdentifier
        case platformIdentifier
        case version
        case build
        case supportedArchitectures
        case sizeBytes
        case lastUsedAt
        case deletable
        case state
    }
}
