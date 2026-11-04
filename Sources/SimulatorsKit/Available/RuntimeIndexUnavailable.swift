import Foundation

/// Apple's runtime index answered with something other than success.
public struct RuntimeIndexUnavailable: LocalizedError, Equatable, Sendable {
    public let statusCode: Int

    public var errorDescription: String? {
        "Couldn't load Apple's list of simulator runtimes (HTTP \(statusCode)). Try again later."
    }
}
