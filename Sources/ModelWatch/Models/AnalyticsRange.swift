enum AnalyticsRange: String, CaseIterable, Identifiable {
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
}
