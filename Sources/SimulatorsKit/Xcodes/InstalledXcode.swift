/// An Xcode installed on this Mac.
public struct InstalledXcode: Equatable, Sendable {
    /// The app bundle, for example `/Applications/Xcode-27.2.0.app`.
    public let path: String
    /// For example `27.2`.
    public let version: String
    /// For example `27B52`.
    public let build: String

    public init(path: String, version: String, build: String) {
        self.path = path
        self.version = version
        self.build = build
    }

    /// For example `Xcode 27.2`.
    public var name: String {
        "Xcode \(version)"
    }

    /// What `DEVELOPER_DIR` points at to make tools use this Xcode.
    public var developerDirectory: String {
        path + "/Contents/Developer"
    }
}
