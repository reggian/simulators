import Foundation

/// Loads Apple's index of downloadable simulator runtimes. Tests replace it with a fixture.
public protocol RuntimeIndexLoader: Sendable {
    /// The index as property list data.
    func loadIndex() async throws -> Data
}
