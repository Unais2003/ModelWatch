import Observation

@Observable
final class MenuBarViewModel {
    private let activityTrackingService: any ActivityTrackingService

    init(activityTrackingService: any ActivityTrackingService) {
        self.activityTrackingService = activityTrackingService
    }

    var statusTitle: String {
        let state = activityTrackingService.currentState()

        guard state.isMonitoring else {
            return "Monitoring Paused"
        }

        return state.activeApplicationName ?? "Monitoring Active"
    }
}
