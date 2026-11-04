/// `simctl` unregistered a runtime but left its downloaded files (a MobileAsset) on disk.
///
/// The files sit under `/System/Library/AssetsV2`, which System Integrity Protection guards, so
/// nobody can remove them by hand. `simctl runtime scan-and-mount` registers the runtime again in
/// the background, after a while, and deleting it once more then removes the files.
public struct RuntimeAssetKept: Error, Equatable, Sendable {
    /// Where the files were left, when `simctl` says so.
    public let assetPath: String?

    public init(assetPath: String?) {
        self.assetPath = assetPath
    }

    /// Recognises the failure from `simctl runtime delete`, which exits with
    /// `SimDiskImageError` code 30 and names the kept asset in its message.
    init?(_ failure: CommandFailure) {
        guard failure.exitCode == 30, failure.standardError.contains("SimDiskImageError") else { return nil }
        let path = failure.standardError.firstMatch(of: /MobileAsset: (\/\S+)/).map { String($0.1) }
        self.init(assetPath: path)
    }
}
