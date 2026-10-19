import Foundation

enum RenewalReminderServiceError: LocalizedError {
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "Notifications are disabled for ModelWatch. Enable them in System Settings to use renewal reminders."
        }
    }
}

@MainActor
protocol RenewalReminderService: AnyObject {
    var isEnabled: Bool { get }

    func setEnabled(_ isEnabled: Bool) async throws
    func synchronize() async throws
}

@MainActor
final class NoOpRenewalReminderService: RenewalReminderService {
    var isEnabled: Bool { false }

    func setEnabled(_ isEnabled: Bool) async throws {
    }

    func synchronize() async throws {
    }
}

@MainActor
final class LocalRenewalReminderService: RenewalReminderService {
    private let subscriptionStore: any SubscriptionStore
    private let preferencesStore: any RenewalReminderPreferencesStore
    private let notificationService: any NotificationSchedulingService
    private let dateProvider: any DateProvider

    init(
        subscriptionStore: any SubscriptionStore,
        preferencesStore: any RenewalReminderPreferencesStore,
        notificationService: any NotificationSchedulingService,
        dateProvider: any DateProvider
    ) {
        self.subscriptionStore = subscriptionStore
        self.preferencesStore = preferencesStore
        self.notificationService = notificationService
        self.dateProvider = dateProvider
    }

    var isEnabled: Bool {
        preferencesStore.isEnabled
    }

    func setEnabled(_ isEnabled: Bool) async throws {
        guard isEnabled else {
            preferencesStore.isEnabled = false
            await notificationService.removeRenewalReminders()
            return
        }

        let status = await notificationService.authorizationStatus()
        switch status {
        case .authorized:
            break
        case .notDetermined:
            guard try await notificationService.requestAuthorization() else {
                preferencesStore.isEnabled = false
                throw RenewalReminderServiceError.authorizationDenied
            }
        case .denied:
            preferencesStore.isEnabled = false
            await notificationService.removeRenewalReminders()
            throw RenewalReminderServiceError.authorizationDenied
        }

        try await replaceReminders()
        preferencesStore.isEnabled = true
    }

    func synchronize() async throws {
        guard preferencesStore.isEnabled else { return }

        guard await notificationService.authorizationStatus() == .authorized else {
            preferencesStore.isEnabled = false
            await notificationService.removeRenewalReminders()
            throw RenewalReminderServiceError.authorizationDenied
        }

        try await replaceReminders()
    }

    private func replaceReminders() async throws {
        let now = dateProvider.now
        let subscriptions = try await subscriptionStore.fetchSubscriptions()
        let reminders: [RenewalReminderRequest] = subscriptions.compactMap { subscription in
            guard subscription.isActive,
                  let renewalDate = subscription.renewalDate,
                  renewalDate > now
            else {
                return nil
            }

            return RenewalReminderRequest(
                subscriptionID: subscription.id,
                renewalDate: renewalDate
            )
        }

        try await notificationService.replaceRenewalReminders(with: reminders)
    }
}
