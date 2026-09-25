import Foundation

enum AnalyticsRange: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            "Today"
        case .week:
            "This Week"
        case .month:
            "This Month"
        }
    }

    func dateInterval(containing date: Date, calendar: Calendar) -> DateInterval? {
        let component: Calendar.Component = switch self {
        case .day:
            .day
        case .week:
            .weekOfYear
        case .month:
            .month
        }

        return calendar.dateInterval(of: component, for: date)
    }
}
