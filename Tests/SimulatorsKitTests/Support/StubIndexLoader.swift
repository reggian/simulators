import Foundation
import SimulatorsKit
import Testing

/// Returns a canned runtime index.
struct StubIndexLoader: RuntimeIndexLoader {
    let data: Data

    func loadIndex() async throws -> Data {
        data
    }

    /// The trimmed copy of Apple's index in `Fixtures/runtime-index.plist`.
    static func fixture() throws -> StubIndexLoader {
        let url = try #require(Bundle.module.url(forResource: "runtime-index", withExtension: "plist", subdirectory: "Fixtures"))
        return StubIndexLoader(data: try Data(contentsOf: url))
    }
}
