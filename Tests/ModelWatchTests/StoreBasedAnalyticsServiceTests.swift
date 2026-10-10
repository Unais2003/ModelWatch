import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class StoreBasedAnalyticsServiceTests: XCTestCase {
    func testSnapshotCountsOnlySessionOverlapThroughNow() async throws {
        let calendar = utcCalendar()
        let now = date(2026, 9, 25, 12, calendar: calendar)
        let startOfDay = date(2026, 9, 25, 0, calendar: calendar)
        let store = AnalyticsSessionStoreStub(sessions: [
            makeSession(
                bundleIdentifier: "test.chatgpt",
                applicationName: "ChatGPT",
                start: startOfDay.addingTimeInterval(-30 * 60),
                end: startOfDay.addingTimeInterval(30 * 60)
            ),
            makeSession(
                bundleIdentifier: "test.chatgpt",
                applicationName: "ChatGPT",
                start: startOfDay.addingTimeInterval(60 * 60),
                end: startOfDay.addingTimeInterval(2 * 60 * 60)
            ),
            makeSession(
                bundleIdentifier: "test.cursor",
                applicationName: "Cursor",
                start: startOfDay.addingTimeInterval(10 * 60 * 60),
                end: nil
            ),
            makeSession(
                bundleIdentifier: "test.invalid",
                applicationName: "Invalid",
                start: startOfDay.addingTimeInterval(11 * 60 * 60),
                end: startOfDay.addingTimeInterval(10 * 60 * 60)
            ),
            makeSession(
                bundleIdentifier: "test.future",
                applicationName: "Future",
                start: startOfDay.addingTimeInterval(13 * 60 * 60),
                end: startOfDay.addingTimeInterval(14 * 60 * 60)
            ),
        ])
        let service = StoreBasedAnalyticsService(
            sessionStore: store,
            dateProvider: FixedAnalyticsDateProvider(now: now),
            calendar: calendar
        )

        let snapshot = try await service.analytics(for: .day)

        XCTAssertEqual(snapshot.summary.range, .day)
        XCTAssertEqual(snapshot.summary.totalDuration, 3.5 * 60 * 60, accuracy: 0.001)
        XCTAssertEqual(snapshot.summary.trackedApplicationCount, 2)
        XCTAssertEqual(snapshot.usageByApplication.map(\.applicationName), ["Cursor", "ChatGPT"])
        XCTAssertEqual(
            snapshot.usageByApplication.map(\.duration),
            [TimeInterval(2 * 60 * 60), TimeInterval(1.5 * 60 * 60)]
        )
        XCTAssertEqual(store.requestedIntervals, [DateInterval(start: startOfDay, duration: 24 * 60 * 60)])
    }

    func testSnapshotGroupsByBundleIdentifierAndKeepsLatestName() async throws {
        let calendar = utcCalendar()
        let now = date(2026, 9, 25, 12, calendar: calendar)
        let startOfDay = date(2026, 9, 25, 0, calendar: calendar)
        let store = AnalyticsSessionStoreStub(sessions: [
            makeSession(
                bundleIdentifier: "com.example.editor",
                applicationName: "Old Name",
                start: startOfDay.addingTimeInterval(60 * 60),
                end: startOfDay.addingTimeInterval(2 * 60 * 60)
            ),
            makeSession(
                bundleIdentifier: "com.example.editor",
                applicationName: "New Name",
                start: startOfDay.addingTimeInterval(3 * 60 * 60),
                end: startOfDay.addingTimeInterval(4 * 60 * 60)
            ),
        ])
        let service = StoreBasedAnalyticsService(
            sessionStore: store,
            dateProvider: FixedAnalyticsDateProvider(now: now),
            calendar: calendar
        )

        let snapshot = try await service.analytics(for: .day)

        XCTAssertEqual(
            snapshot.usageByApplication,
            [
                AppUsage(
                    applicationBundleIdentifier: "com.example.editor",
                    applicationName: "New Name",
                    duration: 2 * 60 * 60
                )
            ]
        )
    }

    private func makeSession(
        bundleIdentifier: String,
        applicationName: String,
        start: Date,
        end: Date?
    ) -> ActivitySession {
        ActivitySession(
            applicationBundleIdentifier: bundleIdentifier,
            applicationName: applicationName,
            startedAt: start,
            endedAt: end
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}

@MainActor
private final class AnalyticsSessionStoreStub: ActivitySessionStore {
    let sessions: [ActivitySession]
    private(set) var requestedIntervals: [DateInterval] = []

    init(sessions: [ActivitySession]) {
        self.sessions = sessions
    }

    func fetchSessions(overlapping interval: DateInterval) async throws -> [ActivitySession] {
        requestedIntervals.append(interval)
        return sessions
    }

    func fetchAllSessions() async throws -> [ActivitySession] {
        sessions
    }

    func fetchUnfinishedSessions() async throws -> [ActivitySession] {
        sessions.filter { $0.endedAt == nil }
    }

    func save(_ session: ActivitySession) async throws {
    }

    func update(_ session: ActivitySession) async throws {
    }

    func delete(_ session: ActivitySession) async throws {
    }

    func deleteAllSessions() async throws {
    }
}

@MainActor
private struct FixedAnalyticsDateProvider: DateProvider {
    let now: Date
}
