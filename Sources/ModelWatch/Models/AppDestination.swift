enum AppDestination: String, CaseIterable, Identifiable {
    case overview
    case subscriptions
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            "Overview"
        case .subscriptions:
            "Subscriptions"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "chart.bar"
        case .subscriptions:
            "creditcard"
        case .settings:
            "gearshape"
        }
    }
}
