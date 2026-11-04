import Foundation
import SimulatorsKit

/// Serves a small runtime index built from the given entries.
struct StubIndexLoader: RuntimeIndexLoader {
    struct Entry {
        /// The index's platform identifier suffix, for example `iphoneos`.
        let platform: String
        let name: String
        let version: String
        let build: String
        let architectures: [String]
        let fileSize: Int64
    }

    let entries: [Entry]

    func loadIndex() async throws -> Data {
        let downloadables: [[String: Any]] = entries.map { entry in
            [
                "name": entry.name,
                "platform": "com.apple.platform.\(entry.platform)",
                "contentType": "cryptexDiskImage",
                "simulatorVersion": ["version": entry.version, "buildUpdate": entry.build],
                "architectures": entry.architectures,
                "fileSize": entry.fileSize,
            ]
        }
        return try PropertyListSerialization.data(
            fromPropertyList: ["downloadables": downloadables],
            format: .xml,
            options: 0
        )
    }
}
