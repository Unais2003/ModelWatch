struct ActivityTrackingState: Equatable {
    let isMonitoring: Bool
    let activeApplicationName: String?

    static let inactive = ActivityTrackingState(
        isMonitoring: false,
        activeApplicationName: nil
    )
}
