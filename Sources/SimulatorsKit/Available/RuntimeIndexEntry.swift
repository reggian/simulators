/// One downloadable in Apple's runtime index (`index2.dvtdownloadableindex`).
struct RuntimeIndexEntry: Decodable {
    let name: String
    /// For example `com.apple.platform.iphoneos`.
    let platform: String
    /// `cryptexDiskImage` for current runtimes; older formats are `diskImage` and `package`.
    let contentType: String
    let simulatorVersion: SimulatorVersion
    let architectures: [String]?
    let fileSize: Int64

    struct SimulatorVersion: Decodable {
        let version: String
        let buildUpdate: String
    }

    /// Whether the runtime installs without signing in to an Apple account (Xcode 16.1 and
    /// later). The tool only offers these.
    var isCurrentFormat: Bool {
        contentType == "cryptexDiskImage"
    }
}
