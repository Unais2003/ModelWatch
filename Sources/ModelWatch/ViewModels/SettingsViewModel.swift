import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    let appName = AppConstants.appName
    let versionDescription = AppConstants.versionDescription
    let minimumSystemVersion = AppConstants.minimumSystemVersion

    private let activityTrackingService: any ActivityTrackingService
    private let dataManagementService: any DataManagementService
    private let launchAtLoginService: any LaunchAtLoginService
    private let renewalReminderService: any RenewalReminderService

    private(set) var applicationSelectionError: String?
    private(set) var localDataSummary = LocalDataSummary.empty
    private(set) var localDataState: DashboardLoadState = .idle
    private(set) var isPerformingDataOperation = false
    private(set) var dataOperationError: String?
    private(set) var dataOperationMessage: String?
    private(set) var launchAtLoginStatus = LaunchAtLoginStatus.unavailable
    private(set) var isUpdatingLaunchAtLogin = false
    private(set) var launchAtLoginError: String?
    private(set) var isUpdatingRenewalReminders = false
    private(set) var renewalReminderError: String?
    private(set) var areRenewalRemindersEnabled: Bool

    init(
        activityTrackingService: any ActivityTrackingService,
        dataManagementService: any DataManagementService,
        launchAtLoginService: any LaunchAtLoginService,
        renewalReminderService: any RenewalReminderService
    ) {
        self.activityTrackingService = activityTrackingService
        self.dataManagementService = dataManagementService
        self.launchAtLoginService = launchAtLoginService
        self.renewalReminderService = renewalReminderService
        launchAtLoginStatus = launchAtLoginService.status
        areRenewalRemindersEnabled = renewalReminderService.isEnabled
    }

    convenience init(
        activityTrackingService: any ActivityTrackingService,
        dataManagementService: any DataManagementService,
        launchAtLoginService: any LaunchAtLoginService
    ) {
        self.init(
            activityTrackingService: activityTrackingService,
            dataManagementService: dataManagementService,
            launchAtLoginService: launchAtLoginService,
            renewalReminderService: NoOpRenewalReminderService()
        )
    }

    convenience init(activityTrackingService: any ActivityTrackingService) {
        self.init(
            activityTrackingService: activityTrackingService,
            dataManagementService: NoOpDataManagementService(),
            launchAtLoginService: NoOpLaunchAtLoginService()
        )
    }

    convenience init(
        activityTrackingService: any ActivityTrackingService,
        dataManagementService: any DataManagementService
    ) {
        self.init(
            activityTrackingService: activityTrackingService,
            dataManagementService: dataManagementService,
            launchAtLoginService: NoOpLaunchAtLoginService()
        )
    }

    var isLaunchAtLoginRequested: Bool {
        launchAtLoginStatus.isRequested
    }

    var renewalReminderStatusMessage: String {
        if areRenewalRemindersEnabled {
            return "ModelWatch will notify you three days before active subscriptions renew."
        }

        return "Off by default. Notification permission is requested only when you enable reminders."
    }

    var launchAtLoginStatusMessage: String {
        switch launchAtLoginStatus {
        case .disabled:
            "ModelWatch will not start automatically when you sign in."
        case .enabled:
            "ModelWatch will start automatically when you sign in."
        case .requiresApproval:
            "Approval is required in System Settings → General → Login Items."
        case .unavailable:
            "Launch at login is available after ModelWatch is installed as a signed app."
        }
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

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginService.status
    }

    func refreshRenewalReminderStatus() {
        areRenewalRemindersEnabled = renewalReminderService.isEnabled
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        Task {
            _ = await updateLaunchAtLoginEnabled(isEnabled)
        }
    }

    @discardableResult
    func updateLaunchAtLoginEnabled(_ isEnabled: Bool) async -> Bool {
        guard !isUpdatingLaunchAtLogin else { return false }

        isUpdatingLaunchAtLogin = true
        launchAtLoginError = nil
        defer { isUpdatingLaunchAtLogin = false }

        do {
            try await launchAtLoginService.setEnabled(isEnabled)
            launchAtLoginStatus = launchAtLoginService.status
            return true
        } catch {
            launchAtLoginError = "Unable to update launch at login. Please try again."
            launchAtLoginStatus = launchAtLoginService.status
            return false
        }
    }

    func openLoginItemsSettings() {
        launchAtLoginService.openSystemSettings()
    }

    func setRenewalRemindersEnabled(_ isEnabled: Bool) {
        Task {
            _ = await updateRenewalRemindersEnabled(isEnabled)
        }
    }

    @discardableResult
    func updateRenewalRemindersEnabled(_ isEnabled: Bool) async -> Bool {
        guard !isUpdatingRenewalReminders else { return false }

        isUpdatingRenewalReminders = true
        renewalReminderError = nil
        defer { isUpdatingRenewalReminders = false }

        do {
            try await renewalReminderService.setEnabled(isEnabled)
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
            return true
        } catch let error as LocalizedError {
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
            renewalReminderError = error.errorDescription
                ?? "Unable to update renewal reminders. Please try again."
            return false
        } catch {
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
            renewalReminderError = "Unable to update renewal reminders. Please try again."
            return false
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

    func loadLocalDataSummary() async {
        localDataState = .loading

        do {
            let summary = try await dataManagementService.summary()
            localDataSummary = summary
            localDataState = summary.isEmpty ? .empty : .loaded
        } catch {
            localDataState = .failed(message: "Unable to inspect local data. Please try again.")
        }
    }

    func prepareExport() async -> ModelWatchExportDocument? {
        guard !isPerformingDataOperation else { return nil }

        isPerformingDataOperation = true
        dataOperationError = nil
        dataOperationMessage = nil
        defer { isPerformingDataOperation = false }

        do {
            return ModelWatchExportDocument(data: try await dataManagementService.exportData())
        } catch {
            dataOperationError = "Unable to prepare the export. Please try again."
            return nil
        }
    }

    func deleteActivityHistory() async -> Bool {
        await performDataDeletion(successMessage: "Activity history deleted.") {
            try await dataManagementService.deleteActivityHistory()
        }
    }

    func deleteSubscriptions() async -> Bool {
        let succeeded = await performDataDeletion(successMessage: "Subscription data deleted.") {
            try await dataManagementService.deleteSubscriptions()
        }
        if succeeded {
            await synchronizeRenewalReminders()
        }
        return succeeded
    }

    func deleteAllData() async -> Bool {
        let succeeded = await performDataDeletion(successMessage: "All activity and subscription data deleted.") {
            try await dataManagementService.deleteAllData()
        }
        if succeeded {
            await synchronizeRenewalReminders()
        }
        return succeeded
    }

    func reportExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            dataOperationError = nil
            dataOperationMessage = "Export saved."
        case .failure:
            dataOperationMessage = nil
            dataOperationError = "Unable to save the export. Please try again."
        }
    }

    func clearDataOperationFeedback() {
        dataOperationError = nil
        dataOperationMessage = nil
    }

    private func performDataDeletion(
        successMessage: String,
        operation: () async throws -> Void
    ) async -> Bool {
        guard !isPerformingDataOperation else { return false }

        isPerformingDataOperation = true
        dataOperationError = nil
        dataOperationMessage = nil
        defer { isPerformingDataOperation = false }

        do {
            try await operation()
            dataOperationMessage = successMessage
            await loadLocalDataSummary()
            return true
        } catch {
            dataOperationError = "Unable to complete the deletion. The data summary has been refreshed."
            await loadLocalDataSummary()
            return false
        }
    }

    private func synchronizeRenewalReminders() async {
        do {
            try await renewalReminderService.synchronize()
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
        } catch let error as LocalizedError {
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
            renewalReminderError = error.errorDescription
                ?? "Local data was updated, but renewal reminders could not be refreshed."
        } catch {
            areRenewalRemindersEnabled = renewalReminderService.isEnabled
            renewalReminderError = "Local data was updated, but renewal reminders could not be refreshed."
        }
    }
}
