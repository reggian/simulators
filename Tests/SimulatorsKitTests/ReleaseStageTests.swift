import Testing
@testable import SimulatorsKit

@Suite("Release stage")
struct ReleaseStageTests {
    @Test("Reads the stage from an index entry's name", arguments: [
        ("iOS 27.2 Simulator Runtime", ReleaseStage.release),
        ("iOS 27.3 beta Simulator Runtime", .beta(nil)),
        ("iOS 27.2 beta 4 Simulator Runtime", .beta(4)),
        ("iOS 27.1 Release Candidate Simulator Runtime", .releaseCandidate),
    ])
    func parsesName(name: String, expected: ReleaseStage) {
        #expect(ReleaseStage(name: name) == expected)
    }
}
