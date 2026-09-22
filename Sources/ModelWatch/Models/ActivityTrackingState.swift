struct ActivityTrackingState: Equatable, Sendable {
    let isMonitoring: Bool
    let activeApplicationName: String?

    static let inactive = ActivityTrackingState(
        isMonitoring: false,
        activeApplicationName: nil
    )
}
