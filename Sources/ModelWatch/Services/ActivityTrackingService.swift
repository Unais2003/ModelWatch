@MainActor
protocol ActivityTrackingService: AnyObject {
    var state: ActivityTrackingState { get }
    var isMonitoringEnabled: Bool { get }
    var trackedApplications: [TrackedApplication] { get }
    var analyticsRevision: Int { get }

    func start() async
    func prepareForTermination() async
    func setMonitoringEnabled(_ isEnabled: Bool) async
    func addTrackedApplication(_ application: TrackedApplication) async
    func removeTrackedApplication(bundleIdentifier: String) async
}

@MainActor
final class NoOpActivityTrackingService: ActivityTrackingService {
    let state = ActivityTrackingState.inactive
    let isMonitoringEnabled = false
    let trackedApplications: [TrackedApplication] = []
    let analyticsRevision = 0

    func start() async {
    }

    func prepareForTermination() async {
    }

    func setMonitoringEnabled(_ isEnabled: Bool) async {
    }

    func addTrackedApplication(_ application: TrackedApplication) async {
    }

    func removeTrackedApplication(bundleIdentifier: String) async {
    }
}
