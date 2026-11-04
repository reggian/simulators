import Foundation

/// Describes when a runtime was last used, in whole calendar days: `today`, `yesterday` or
/// `5 days ago`.
///
/// `simctl` sometimes reports no date at all. That doesn't necessarily mean the runtime was never
/// used, so it's shown as `-`.
struct LastUsedDescription {
    let now: Date
    let calendar: Calendar

    func describe(_ lastUsed: Date?) -> String {
        guard let lastUsed else { return "-" }

        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastUsed),
            to: calendar.startOfDay(for: now)
        ).day ?? 0

        switch days {
        case ...0: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }
}
