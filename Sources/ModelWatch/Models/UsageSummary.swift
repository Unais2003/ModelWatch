import Foundation

struct UsageSummary: Equatable {
    let range: AnalyticsRange
    let totalDuration: TimeInterval
    let trackedApplicationCount: Int

    static func empty(range: AnalyticsRange) -> UsageSummary {
        UsageSummary(
            range: range,
            totalDuration: 0,
            trackedApplicationCount: 0
        )
    }
}
