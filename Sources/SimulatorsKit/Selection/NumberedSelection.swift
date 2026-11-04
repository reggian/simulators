import Foundation

/// Parses what a user types to pick items from a numbered list, such as `1 3`, `2-4`, `1, 5-6`
/// or `all`. Numbers are 1-based, as shown on screen.
public struct NumberedSelection: Sendable {
    public enum Error: LocalizedError, Equatable, Sendable {
        case invalidToken(String)
        case outOfRange(Int, count: Int)
        case reversedRange(String)

        public var errorDescription: String? {
            switch self {
            case let .invalidToken(token):
                "\"\(token)\" isn't a number, a range like 2-4, or \"all\"."
            case let .outOfRange(number, count):
                "\(number) isn't in the list. Pick numbers from 1 to \(count)."
            case let .reversedRange(range):
                "\(range) is backwards. Write the smaller number first."
            }
        }
    }

    /// How many items the list has.
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    /// Returns the selected 0-based indices in ascending order, without duplicates. Empty input
    /// selects nothing.
    public func indices(from input: String) throws -> [Int] {
        let tokens = input
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .map { $0.lowercased() }

        if tokens == ["all"] {
            return Array(0..<count)
        }

        var selected = Set<Int>()
        for token in tokens {
            for number in try numbers(in: token) {
                guard (1...count).contains(number) else {
                    throw Error.outOfRange(number, count: count)
                }
                selected.insert(number - 1)
            }
        }
        return selected.sorted()
    }

    private func numbers(in token: String) throws -> ClosedRange<Int> {
        let bounds = token.split(separator: "-", omittingEmptySubsequences: false)
        switch bounds.count {
        case 1:
            guard let number = Int(bounds[0]) else { throw Error.invalidToken(token) }
            return number...number
        case 2:
            guard let lower = Int(bounds[0]), let upper = Int(bounds[1]) else {
                throw Error.invalidToken(token)
            }
            guard lower <= upper else { throw Error.reversedRange(token) }
            return lower...upper
        default:
            throw Error.invalidToken(token)
        }
    }
}
