import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class WorkspaceActivityTrackingServiceTests: XCTestCase {
    private let chatGPT = TrackedApplication(
        bundleIdentifier: "test.chatgpt",
        displayName: "ChatGPT"
    )
    private let cursor = TrackedApplication(
        bundleIdentifier: "test.cursor",
        displayName: "Cursor"
    )

    func testMonitoringRemainsOffUntilUserEnablesIt() async {
        let fixture = makeFixture(
            isEnabled: false,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )

        await fixture.service.start()

        XCTAssertEqual(fixture.service.state, .inactive)
        XCTAssertTrue(fixture.store.sessions.isEmpty)
    }

    func testMonitoringCannotStartWithoutApprovedApplications() async {
        let fixture = makeFixture(
            isEnabled: false,
            applications: [],
            frontmostApplication: nil
        )

        await fixture.service.setMonitoringEnabled(true)

        XCTAssertFalse(fixture.service.isMonitoringEnabled)
        XCTAssertFalse(fixture.preferences.isMonitoringEnabled)
        XCTAssertEqual(fixture.service.state, .inactive)
    }

    func testEnablingMonitoringStartsSessionForApprovedFrontmostApplication() async {
        let fixture = makeFixture(
            isEnabled: false,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )

        await fixture.service.setMonitoringEnabled(true)

        XCTAssertTrue(fixture.preferences.isMonitoringEnabled)
        XCTAssertEqual(
            fixture.service.state,
            .monitoring(activeApplicationName: chatGPT.displayName)
        )
        XCTAssertEqual(fixture.store.sessions.count, 1)
        XCTAssertEqual(fixture.store.sessions[0].applicationBundleIdentifier, chatGPT.bundleIdentifier)
        XCTAssertNil(fixture.store.sessions[0].endedAt)
    }

    func testSwitchingTrackedApplicationsClosesOldSessionAndStartsNewSession() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT, cursor],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_600)
        await fixture.service.process(.applicationActivated(workspaceApplication(cursor)))

        XCTAssertEqual(fixture.store.sessions.count, 2)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
        XCTAssertEqual(fixture.store.sessions[1].applicationBundleIdentifier, cursor.bundleIdentifier)
        XCTAssertNil(fixture.store.sessions[1].endedAt)
        XCTAssertEqual(
            fixture.service.state,
            .monitoring(activeApplicationName: cursor.displayName)
        )
    }

    func testDuplicateActivationDoesNotCreateAnotherSession() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_100)
        await fixture.service.process(.applicationActivated(workspaceApplication(chatGPT)))

        XCTAssertEqual(fixture.store.sessions.count, 1)
        XCTAssertNil(fixture.store.sessions[0].endedAt)
    }

    func testUnapprovedApplicationClosesCurrentSessionWithoutStartingAnother() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_200)
        await fixture.service.process(
            .applicationActivated(
                WorkspaceApplication(bundleIdentifier: "test.mail", displayName: "Mail")
            )
        )

        XCTAssertEqual(fixture.store.sessions.count, 1)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
        XCTAssertEqual(fixture.service.state, .monitoring())
    }

    func testSleepClosesSessionAndWakeResumesFrontmostApprovedApplication() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT, cursor],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_300)
        await fixture.service.process(.willSleep)

        XCTAssertEqual(fixture.service.state, .inactive)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)

        fixture.eventSource.frontmostApplication = workspaceApplication(cursor)
        fixture.clock.now = Date(timeIntervalSince1970: 1_400)
        await fixture.service.process(.didWake)

        XCTAssertEqual(fixture.store.sessions.count, 2)
        XCTAssertEqual(fixture.store.sessions[1].applicationBundleIdentifier, cursor.bundleIdentifier)
        XCTAssertEqual(
            fixture.service.state,
            .monitoring(activeApplicationName: cursor.displayName)
        )
    }

    func testPausingMonitoringClosesSessionAndPersistsPreference() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_500)
        await fixture.service.setMonitoringEnabled(false)

        XCTAssertFalse(fixture.preferences.isMonitoringEnabled)
        XCTAssertEqual(fixture.service.state, .inactive)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
    }

    func testTerminationClosesSessionWithoutDisablingNextLaunch() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_550)
        await fixture.service.process(.willTerminate)

        XCTAssertTrue(fixture.preferences.isMonitoringEnabled)
        XCTAssertEqual(fixture.service.state, .inactive)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
    }

    func testRemovingActiveApplicationClosesItsSession() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT, cursor],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_700)
        await fixture.service.removeTrackedApplication(bundleIdentifier: chatGPT.bundleIdentifier)

        XCTAssertEqual(fixture.service.trackedApplications, [cursor])
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
        XCTAssertEqual(fixture.service.state, .monitoring())
    }

    func testRemovingLastApprovedApplicationAlsoPausesMonitoring() async {
        let fixture = makeFixture(
            isEnabled: true,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        await fixture.service.start()

        fixture.clock.now = Date(timeIntervalSince1970: 1_750)
        await fixture.service.removeTrackedApplication(bundleIdentifier: chatGPT.bundleIdentifier)

        XCTAssertFalse(fixture.service.isMonitoringEnabled)
        XCTAssertFalse(fixture.preferences.isMonitoringEnabled)
        XCTAssertEqual(fixture.service.state, .inactive)
        XCTAssertEqual(fixture.store.sessions[0].endedAt, fixture.clock.now)
    }

    func testStartupDiscardsUnfinishedCrashSessionBeforeTracking() async {
        let unfinishedSession = ActivitySession(
            applicationBundleIdentifier: chatGPT.bundleIdentifier,
            applicationName: chatGPT.displayName,
            startedAt: Date(timeIntervalSince1970: 100)
        )
        let fixture = makeFixture(
            isEnabled: true,
            applications: [],
            frontmostApplication: nil,
            existingSessions: [unfinishedSession]
        )

        await fixture.service.start()

        XCTAssertTrue(fixture.store.sessions.isEmpty)
        XCTAssertEqual(fixture.service.state, .inactive)
    }

    func testPersistenceFailureStopsMonitoringWithVisibleError() async {
        let fixture = makeFixture(
            isEnabled: false,
            applications: [chatGPT],
            frontmostApplication: workspaceApplication(chatGPT)
        )
        fixture.store.shouldFail = true

        await fixture.service.setMonitoringEnabled(true)

        guard let message = fixture.service.state.errorMessage else {
            return XCTFail("Expected a visible monitoring failure")
        }
        XCTAssertFalse(message.isEmpty)
    }

    private func makeFixture(
        isEnabled: Bool,
        applications: [TrackedApplication],
        frontmostApplication: WorkspaceApplication?,
        existingSessions: [ActivitySession] = []
    ) -> TrackingFixture {
        let store = TrackingSessionStoreSpy(sessions: existingSessions)
        let preferences = TrackingPreferencesStoreSpy(
            isMonitoringEnabled: isEnabled,
            trackedApplications: applications
        )
        let eventSource = WorkspaceActivityEventSourceSpy(
            frontmostApplication: frontmostApplication
        )
        let clock = MutableDateProvider(now: Date(timeIntervalSince1970: 1_000))
        let service = WorkspaceActivityTrackingService(
            sessionStore: store,
            preferencesStore: preferences,
            eventSource: eventSource,
            dateProvider: clock
        )
        return TrackingFixture(
            service: service,
            store: store,
            preferences: preferences,
            eventSource: eventSource,
            clock: clock
        )
    }

    private func workspaceApplication(_ application: TrackedApplication) -> WorkspaceApplication {
        WorkspaceApplication(
            bundleIdentifier: application.bundleIdentifier,
            displayName: application.displayName
        )
    }
}

@MainActor
private struct TrackingFixture {
    let service: WorkspaceActivityTrackingService
    let store: TrackingSessionStoreSpy
    let preferences: TrackingPreferencesStoreSpy
    let eventSource: WorkspaceActivityEventSourceSpy
    let clock: MutableDateProvider
}

@MainActor
private final class TrackingSessionStoreSpy: ActivitySessionStore {
    var sessions: [ActivitySession]
    var shouldFail = false

    init(sessions: [ActivitySession] = []) {
        self.sessions = sessions
    }

    func fetchSessions(overlapping interval: DateInterval) async throws -> [ActivitySession] {
        try failIfNeeded()
        return sessions
    }

    func fetchUnfinishedSessions() async throws -> [ActivitySession] {
        try failIfNeeded()
        return sessions.filter { $0.endedAt == nil }
    }

    func save(_ session: ActivitySession) async throws {
        try failIfNeeded()
        sessions.append(session)
    }

    func update(_ session: ActivitySession) async throws {
        try failIfNeeded()
    }

    func delete(_ session: ActivitySession) async throws {
        try failIfNeeded()
        sessions.removeAll { $0.id == session.id }
    }

    private func failIfNeeded() throws {
        if shouldFail {
            throw TrackingTestError.expected
        }
    }
}

@MainActor
private final class TrackingPreferencesStoreSpy: ActivityTrackingPreferencesStore {
    var isMonitoringEnabled: Bool
    var trackedApplications: [TrackedApplication]

    init(isMonitoringEnabled: Bool, trackedApplications: [TrackedApplication]) {
        self.isMonitoringEnabled = isMonitoringEnabled
        self.trackedApplications = trackedApplications
    }
}

@MainActor
private final class WorkspaceActivityEventSourceSpy: WorkspaceActivityEventSource {
    var frontmostApplication: WorkspaceApplication?
    private var continuation: AsyncStream<WorkspaceActivityEvent>.Continuation?

    init(frontmostApplication: WorkspaceApplication?) {
        self.frontmostApplication = frontmostApplication
    }

    func events() -> AsyncStream<WorkspaceActivityEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stop() {
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
private final class MutableDateProvider: DateProvider {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

private enum TrackingTestError: Error {
    case expected
}
