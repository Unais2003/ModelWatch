import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    let appName = AppConstants.appName
    let minimumSystemVersion = AppConstants.minimumSystemVersion

    private let activityTrackingService: any ActivityTrackingService

    private(set) var applicationSelectionError: String?

    init(activityTrackingService: any ActivityTrackingService) {
        self.activityTrackingService = activityTrackingService
    }

    var isMonitoringEnabled: Bool {
        activityTrackingService.isMonitoringEnabled
    }

    var trackedApplications: [TrackedApplication] {
        activityTrackingService.trackedApplications
    }

    var monitoringStatus: String {
        if trackedApplications.isEmpty {
            return "Select at least one application before enabling monitoring."
        }

        let state = activityTrackingService.state

        if let errorMessage = state.errorMessage {
            return errorMessage
        }

        guard state.isMonitoring else {
            return "Monitoring is paused."
        }

        if let applicationName = state.activeApplicationName {
            return "Tracking \(applicationName)."
        }

        return "Monitoring is active. No approved application is currently in use."
    }

    var hasMonitoringError: Bool {
        activityTrackingService.state.errorMessage != nil
    }

    func setMonitoringEnabled(_ isEnabled: Bool) {
        Task {
            await activityTrackingService.setMonitoringEnabled(isEnabled)
        }
    }

    func addApplication(at url: URL) async {
        let hasSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              !bundleIdentifier.isEmpty
        else {
            applicationSelectionError = "The selected item is not a valid macOS application."
            return
        }

        guard bundleIdentifier != AppConstants.bundleIdentifier else {
            applicationSelectionError = "ModelWatch cannot track itself."
            return
        }

        let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent

        await activityTrackingService.addTrackedApplication(
            TrackedApplication(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName
            )
        )
        applicationSelectionError = nil
    }

    func removeApplication(_ application: TrackedApplication) {
        Task {
            await activityTrackingService.removeTrackedApplication(
                bundleIdentifier: application.bundleIdentifier
            )
        }
    }
}
