import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class RenewalReminderServiceTests: XCTestCase {
    func testUserDefaultsPreferencePersistsAcrossStoreInstances() throws {
        let suiteName = "ModelWatchTests.RenewalReminders.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsRenewalReminderPreferencesStore(defaults: defaults)
        XCTAssertFalse(store.isEnabled)

        store.isEnabled = true

        let reloadedStore = UserDefaultsRenewalReminderPreferencesStore(defaults: defaults)
        XCTAssertTrue(reloadedStore.isEnabled)
    }

    func testEnablingRequestsAuthorizationAndSchedulesOnlyEligibleSubscriptions() async throws {
        let now = makeDate(year: 2026, month: 10, day: 19, hour: 12)
        let eligible = Subscription(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            serviceName: "Eligible",
            monthlyCost: 20,
            currencyCode: "USD",
            renewalDate: makeDate(year: 2026, month: 10, day: 25),
            isActive: true
        )
        let subscriptions = [
            eligible,
            Subscription(
                serviceName: "Inactive",
                monthlyCost: 10,
                currencyCode: "USD",
                renewalDate: makeDate(year: 2026, month: 10, day: 25),
                isActive: false
            ),
            Subscription(
                serviceName: "Past",
                monthlyCost: 5,
                currencyCode: "USD",
                renewalDate: makeDate(year: 2026, month: 10, day: 18),
                isActive: true
            ),
            Subscription(
                serviceName: "No Date",
                monthlyCost: 15,
                currencyCode: "USD",
                renewalDate: nil,
                isActive: true
            ),
        ]
        let preferences = InMemoryRenewalReminderPreferencesStore()
        let notifications = NotificationSchedulingServiceSpy(
            status: .notDetermined,
            authorizationResult: true
        )
        let service = makeService(
            subscriptions: subscriptions,
            preferences: preferences,
            notifications: notifications,
            now: now
        )

        try await service.setEnabled(true)

        XCTAssertTrue(service.isEnabled)
        XCTAssertEqual(notifications.requestAuthorizationCallCount, 1)
        XCTAssertEqual(
            notifications.replacementBatches,
            [[
                RenewalReminderRequest(
                    subscriptionID: eligible.id,
                    renewalDate: try XCTUnwrap(eligible.renewalDate)
                ),
            ]]
        )
    }

    func testDeniedAuthorizationLeavesRemindersDisabled() async {
        let preferences = InMemoryRenewalReminderPreferencesStore()
        let notifications = NotificationSchedulingServiceSpy(status: .denied)
        let service = makeService(
            preferences: preferences,
            notifications: notifications,
            now: makeDate(year: 2026, month: 10, day: 19)
        )

        do {
            try await service.setEnabled(true)
            XCTFail("Expected authorization denial")
        } catch let error as RenewalReminderServiceError {
            XCTAssertEqual(error.errorDescription, RenewalReminderServiceError.authorizationDenied.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertFalse(service.isEnabled)
        XCTAssertTrue(notifications.replacementBatches.isEmpty)
    }

    func testDisablingClearsScheduledRemindersAndPreference() async throws {
        let preferences = InMemoryRenewalReminderPreferencesStore(isEnabled: true)
        let notifications = NotificationSchedulingServiceSpy(status: .authorized)
        let service = makeService(
            preferences: preferences,
            notifications: notifications,
            now: makeDate(year: 2026, month: 10, day: 19)
        )

        try await service.setEnabled(false)

        XCTAssertFalse(service.isEnabled)
        XCTAssertEqual(notifications.removeCallCount, 1)
    }

    func testSynchronizationDisablesPreferenceWhenAuthorizationWasRevoked() async {
        let preferences = InMemoryRenewalReminderPreferencesStore(isEnabled: true)
        let notifications = NotificationSchedulingServiceSpy(status: .denied)
        let service = makeService(
            preferences: preferences,
            notifications: notifications,
            now: makeDate(year: 2026, month: 10, day: 19)
        )

        do {
            try await service.synchronize()
            XCTFail("Expected authorization denial")
        } catch {
            XCTAssertFalse(service.isEnabled)
            XCTAssertEqual(notifications.removeCallCount, 1)
        }
    }

    func testDeliveryDateIsThreeDaysBeforeRenewalAtNineAM() {
        let now = makeDate(year: 2026, month: 10, day: 19, hour: 12)
        let renewalDate = makeDate(year: 2026, month: 10, day: 25, hour: 18)

        let deliveryDate = SystemNotificationSchedulingService.reminderDeliveryDate(
            for: renewalDate,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(deliveryDate, makeDate(year: 2026, month: 10, day: 22, hour: 9))
    }

    func testDeliveryDateUsesNearTermAlertInsideThreeDayWindow() {
        let now = makeDate(year: 2026, month: 10, day: 23, hour: 12)
        let renewalDate = makeDate(year: 2026, month: 10, day: 25, hour: 18)

        let deliveryDate = SystemNotificationSchedulingService.reminderDeliveryDate(
            for: renewalDate,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(deliveryDate, now.addingTimeInterval(60))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }

    private func makeService(
        subscriptions: [Subscription] = [],
        preferences: InMemoryRenewalReminderPreferencesStore,
        notifications: NotificationSchedulingServiceSpy,
        now: Date
    ) -> LocalRenewalReminderService {
        LocalRenewalReminderService(
            subscriptionStore: RenewalReminderSubscriptionStoreStub(subscriptions: subscriptions),
            preferencesStore: preferences,
            notificationService: notifications,
            dateProvider: RenewalReminderDateProvider(now: now)
        )
    }
}

@MainActor
private final class NotificationSchedulingServiceSpy: NotificationSchedulingService {
    var status: NotificationAuthorizationStatus
    var authorizationResult: Bool
    private(set) var requestAuthorizationCallCount = 0
    private(set) var replacementBatches: [[RenewalReminderRequest]] = []
    private(set) var removeCallCount = 0

    init(
        status: NotificationAuthorizationStatus,
        authorizationResult: Bool = false
    ) {
        self.status = status
        self.authorizationResult = authorizationResult
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCallCount += 1
        if authorizationResult {
            status = .authorized
        }
        return authorizationResult
    }

    func replaceRenewalReminders(with reminders: [RenewalReminderRequest]) async throws {
        replacementBatches.append(reminders)
    }

    func removeRenewalReminders() async {
        removeCallCount += 1
    }
}

@MainActor
private final class RenewalReminderSubscriptionStoreStub: SubscriptionStore {
    var subscriptions: [Subscription]

    init(subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
    }

    func fetchSubscriptions() async throws -> [Subscription] {
        subscriptions
    }

    func save(_ subscription: Subscription) async throws {
        subscriptions.append(subscription)
    }

    func update(_ subscription: Subscription) async throws {
    }

    func delete(_ subscription: Subscription) async throws {
        subscriptions.removeAll { $0.id == subscription.id }
    }

    func deleteAllSubscriptions() async throws {
        subscriptions.removeAll()
    }
}

@MainActor
private struct RenewalReminderDateProvider: DateProvider {
    let now: Date
}
