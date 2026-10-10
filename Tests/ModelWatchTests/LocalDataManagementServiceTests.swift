import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class LocalDataManagementServiceTests: XCTestCase {
    func testSummaryCountsBothLocalDataCategories() async throws {
        let fixture = makeFixture()

        let summary = try await fixture.service.summary()

        XCTAssertEqual(
            summary,
            LocalDataSummary(activitySessionCount: 1, subscriptionCount: 1)
        )
    }

    func testExportProducesVersionedPortableJSON() async throws {
        let fixture = makeFixture()

        let data = try await fixture.service.exportData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(ModelWatchDataExport.self, from: data)

        XCTAssertEqual(export.schemaVersion, 1)
        XCTAssertEqual(export.exportedAt, fixture.now)
        XCTAssertEqual(export.activitySessions.count, 1)
        XCTAssertEqual(export.activitySessions[0].applicationBundleIdentifier, "test.chatgpt")
        XCTAssertEqual(export.subscriptions.count, 1)
        XCTAssertEqual(export.subscriptions[0].serviceName, "ChatGPT Plus")
        XCTAssertEqual(export.subscriptions[0].currencyCode, "USD")
    }

    func testDeleteSubscriptionsClearsStoreAndAdvancesRevision() async throws {
        let fixture = makeFixture()

        try await fixture.service.deleteSubscriptions()

        XCTAssertTrue(fixture.subscriptionStore.subscriptions.isEmpty)
        XCTAssertEqual(fixture.service.revision, 1)
    }

    func testDeleteActivityHistoryDelegatesToTrackerAndAdvancesRevision() async throws {
        let fixture = makeFixture()

        try await fixture.service.deleteActivityHistory()

        XCTAssertEqual(fixture.trackingService.deleteHistoryCallCount, 1)
        XCTAssertTrue(fixture.sessionStore.sessions.isEmpty)
        XCTAssertEqual(fixture.service.revision, 1)
    }

    func testFailedDeletionDoesNotAdvanceRevision() async {
        let fixture = makeFixture()
        fixture.subscriptionStore.shouldFailDeletion = true

        do {
            try await fixture.service.deleteSubscriptions()
            XCTFail("Expected deletion to fail")
        } catch {
            XCTAssertEqual(fixture.service.revision, 0)
            XCTAssertEqual(fixture.subscriptionStore.subscriptions.count, 1)
        }
    }

    private func makeFixture() -> DataManagementFixture {
        let now = Date(timeIntervalSince1970: 2_000)
        let sessionStore = LocalDataSessionStoreSpy(sessions: [
            ActivitySession(
                applicationBundleIdentifier: "test.chatgpt",
                applicationName: "ChatGPT",
                startedAt: Date(timeIntervalSince1970: 1_000),
                endedAt: Date(timeIntervalSince1970: 1_500)
            )
        ])
        let subscriptionStore = LocalDataSubscriptionStoreSpy(subscriptions: [
            Subscription(
                serviceName: "ChatGPT Plus",
                monthlyCost: 20,
                currencyCode: "USD"
            )
        ])
        let trackingService = LocalDataTrackingServiceSpy(sessionStore: sessionStore)
        let service = LocalDataManagementService(
            sessionStore: sessionStore,
            subscriptionStore: subscriptionStore,
            activityTrackingService: trackingService,
            dateProvider: LocalDataDateProvider(now: now)
        )
        return DataManagementFixture(
            service: service,
            sessionStore: sessionStore,
            subscriptionStore: subscriptionStore,
            trackingService: trackingService,
            now: now
        )
    }
}

@MainActor
private struct DataManagementFixture {
    let service: LocalDataManagementService
    let sessionStore: LocalDataSessionStoreSpy
    let subscriptionStore: LocalDataSubscriptionStoreSpy
    let trackingService: LocalDataTrackingServiceSpy
    let now: Date
}

@MainActor
private final class LocalDataSessionStoreSpy: ActivitySessionStore {
    var sessions: [ActivitySession]

    init(sessions: [ActivitySession]) {
        self.sessions = sessions
    }

    func fetchSessions(overlapping interval: DateInterval) async throws -> [ActivitySession] {
        sessions
    }

    func fetchAllSessions() async throws -> [ActivitySession] {
        sessions
    }

    func fetchUnfinishedSessions() async throws -> [ActivitySession] {
        sessions.filter { $0.endedAt == nil }
    }

    func save(_ session: ActivitySession) async throws {
        sessions.append(session)
    }

    func update(_ session: ActivitySession) async throws {
    }

    func delete(_ session: ActivitySession) async throws {
        sessions.removeAll { $0.id == session.id }
    }

    func deleteAllSessions() async throws {
        sessions.removeAll()
    }
}

@MainActor
private final class LocalDataSubscriptionStoreSpy: SubscriptionStore {
    var subscriptions: [Subscription]
    var shouldFailDeletion = false

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
        if shouldFailDeletion {
            throw LocalDataTestError.expected
        }
        subscriptions.removeAll()
    }
}

@MainActor
private final class LocalDataTrackingServiceSpy: ActivityTrackingService {
    let state = ActivityTrackingState.inactive
    let isMonitoringEnabled = false
    let trackedApplications: [TrackedApplication] = []
    private(set) var analyticsRevision = 0
    private(set) var deleteHistoryCallCount = 0

    private let sessionStore: LocalDataSessionStoreSpy

    init(sessionStore: LocalDataSessionStoreSpy) {
        self.sessionStore = sessionStore
    }

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

    func deleteActivityHistory() async throws {
        deleteHistoryCallCount += 1
        try await sessionStore.deleteAllSessions()
        analyticsRevision += 1
    }
}

@MainActor
private struct LocalDataDateProvider: DateProvider {
    let now: Date
}

private enum LocalDataTestError: Error {
    case expected
}
