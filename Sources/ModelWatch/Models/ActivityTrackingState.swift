struct ActivityTrackingState: Equatable, Sendable {
    let isMonitoring: Bool
    let activeApplicationName: String?
    let errorMessage: String?

    static let inactive = ActivityTrackingState(
        isMonitoring: false,
        activeApplicationName: nil,
        errorMessage: nil
    )

    static func monitoring(activeApplicationName: String? = nil) -> ActivityTrackingState {
        ActivityTrackingState(
            isMonitoring: true,
            activeApplicationName: activeApplicationName,
            errorMessage: nil
        )
    }

    static func failed(message: String) -> ActivityTrackingState {
        ActivityTrackingState(
            isMonitoring: false,
            activeApplicationName: nil,
            errorMessage: message
        )
    }
}
