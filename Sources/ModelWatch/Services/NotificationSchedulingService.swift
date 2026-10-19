import Foundation
import UserNotifications

enum NotificationAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

struct RenewalReminderRequest: Equatable {
    let subscriptionID: UUID
    let renewalDate: Date
}

@MainActor
protocol NotificationSchedulingService {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func replaceRenewalReminders(with reminders: [RenewalReminderRequest]) async throws
    func removeRenewalReminders() async
}

@MainActor
struct NoOpNotificationSchedulingService: NotificationSchedulingService {
    func authorizationStatus() async -> NotificationAuthorizationStatus {
        .denied
    }

    func requestAuthorization() async throws -> Bool {
        false
    }

    func replaceRenewalReminders(with reminders: [RenewalReminderRequest]) async throws {
    }

    func removeRenewalReminders() async {
    }
}

@MainActor
final class SystemNotificationSchedulingService: NotificationSchedulingService {
    private static let renewalReminderIdentifierPrefix = "renewal-reminder."
    private static let reminderLeadDays = 3
    private static let reminderHour = 9
    private static let nearTermDelay: TimeInterval = 60

    private let center: UNUserNotificationCenter
    private let dateProvider: any DateProvider
    private var calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        dateProvider: any DateProvider,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func replaceRenewalReminders(with reminders: [RenewalReminderRequest]) async throws {
        await removeRenewalReminders()

        for reminder in reminders {
            guard let deliveryDate = Self.reminderDeliveryDate(
                for: reminder.renewalDate,
                now: dateProvider.now,
                calendar: calendar
            ) else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Upcoming subscription renewal"
            content.body = "A tracked subscription renews soon. Open ModelWatch to review it."
            content.sound = .default

            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: deliveryDate
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: Self.renewalReminderIdentifierPrefix
                    + reminder.subscriptionID.uuidString,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    func removeRenewalReminders() async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.renewalReminderIdentifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    static func reminderDeliveryDate(
        for renewalDate: Date,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        guard renewalDate > now else { return nil }

        let renewalDay = calendar.startOfDay(for: renewalDate)
        guard let reminderDay = calendar.date(
            byAdding: .day,
            value: -reminderLeadDays,
            to: renewalDay
        ), let scheduledDate = calendar.date(
            bySettingHour: reminderHour,
            minute: 0,
            second: 0,
            of: reminderDay
        ) else {
            return nil
        }

        if scheduledDate > now {
            return scheduledDate
        }

        return now.addingTimeInterval(nearTermDelay)
    }
}
