/// The simulator platform a runtime belongs to, such as iOS or watchOS.
///
/// Unknown platform identifiers are kept rather than rejected, so a new platform from Apple
/// doesn't break listing everything else.
public struct SimulatorPlatform: Hashable, Sendable, Decodable {
    /// CoreSimulator's identifier, for example `com.apple.platform.iphonesimulator`.
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    /// The platform for an identifier from Apple's runtime index, which names the device
    /// platform (`com.apple.platform.iphoneos`) rather than the simulator one
    /// (`com.apple.platform.iphonesimulator`).
    public init(indexPlatform: String) {
        guard indexPlatform.hasSuffix("os") else {
            self.init(identifier: indexPlatform)
            return
        }
        self.init(identifier: indexPlatform.dropLast(2) + "simulator")
    }

    /// The known platform with this display name, ignoring case: `ios`, `watchOS`, `tvOS`,
    /// `visionOS`.
    public static func named(_ name: String) -> SimulatorPlatform? {
        known.first { $0.value.name.lowercased() == name.lowercased() }.map { SimulatorPlatform(identifier: $0.key) }
    }

    public init(from decoder: any Decoder) throws {
        identifier = try decoder.singleValueContainer().decode(String.self)
    }

    /// A display name such as `iOS`. Falls back to the identifier's last component.
    public var name: String {
        Self.known[identifier]?.name ?? identifier.split(separator: ".").last.map(String.init) ?? identifier
    }

    /// Order for listings: iOS, watchOS, tvOS, visionOS, then unknown platforms.
    public var sortOrder: Int {
        Self.known[identifier]?.order ?? Int.max
    }

    private static let known: [String: (name: String, order: Int)] = [
        "com.apple.platform.iphonesimulator": ("iOS", 0),
        "com.apple.platform.watchsimulator": ("watchOS", 1),
        "com.apple.platform.appletvsimulator": ("tvOS", 2),
        "com.apple.platform.xrsimulator": ("visionOS", 3),
    ]
}
