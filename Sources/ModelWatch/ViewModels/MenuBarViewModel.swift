import Observation

@Observable
@MainActor
final class MenuBarViewModel {
    private let activityTrackingService: any ActivityTrackingService

    init(activityTrackingService: any ActivityTrackingService) {
        self.activityTrackingService = activityTrackingService
    }

    var statusTitle: String {
        let state = activityTrackingService.state

        if state.errorMessage != nil {
            return "Monitoring Unavailable"
        }

        guard state.isMonitoring else {
            return "Monitoring Paused"
        }

        return state.activeApplicationName ?? "Monitoring Active"
    }

    var monitoringActionTitle: String {
        activityTrackingService.isMonitoringEnabled ? "Pause Monitoring" : "Start Monitoring"
    }

    var canToggleMonitoring: Bool {
        activityTrackingService.isMonitoringEnabled || !activityTrackingService.trackedApplications.isEmpty
    }

    func toggleMonitoring() {
        let shouldEnable = !activityTrackingService.isMonitoringEnabled
        Task {
            await activityTrackingService.setMonitoringEnabled(shouldEnable)
        }
    }
}
