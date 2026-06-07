protocol ActivityTrackingService {
    func currentState() -> ActivityTrackingState
}

struct NoOpActivityTrackingService: ActivityTrackingService {
    func currentState() -> ActivityTrackingState {
        .inactive
    }
}
