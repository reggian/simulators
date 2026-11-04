import Foundation

extension String {
    /// Compares strings with embedded numbers as numbers (`27.10` after `27.9`, `24B8117` before
    /// `24B91016s`). Returns `nil` when they're equal.
    func numericallyPrecedes(_ other: String) -> Bool? {
        switch compare(other, options: .numeric) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: nil
        }
    }
}
