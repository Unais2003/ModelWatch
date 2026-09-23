import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class StoreBasedAnalyticsServiceTests: XCTestCase {
    func testSummaryAggregatesOnlyCompletedPositiveSessions() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let store = AnalyticsSessionStoreStub(sessions: [
            makeSession(applicationName: "ChatGPT", start: start, duration: 30 * 60),
            makeSession(applicationName: "ChatGPT", start: start, duration: 15 * 60),
            makeSession(applicationName: "Cursor", start: start, duration: 60 * 60),
            makeSession(applicationName: "Claude", start: start, duration: nil),
            makeSession(applicationName: "Invalid", start: start, duration: -60),
        ])
        let service = StoreBasedAnalyticsService(sessionStore: store)

        let summary = try await service.usageSummary(for: .day)

        XCTAssertEqual(summary.range, .day)
        XCTAssertEqual(summary.totalDuration, 105 * 60, accuracy: 0.001)
        XCTAssertEqual(summary.trackedApplicationCount, 2)
    }

    func testBreakdownCombinesApplicationsAndSortsByDuration() async throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let store = AnalyticsSessionStoreStub(sessions: [
            makeSession(applicationName: "ChatGPT", start: start, duration: 30 * 60),
            makeSession(applicationName: "Cursor", start: start, duration: 60 * 60),
            makeSession(applicationName: "ChatGPT", start: start, duration: 15 * 60),
        ])
        let service = StoreBasedAnalyticsService(sessionStore: store)

        let breakdown = try await service.usageByApplication(for: .week)

        XCTAssertEqual(
            breakdown,
            [
                AppUsage(applicationName: "Cursor", duration: 60 * 60),
                AppUsage(applicationName: "ChatGPT", duration: 45 * 60),
            ]
        )
    }

    private func makeSession(
        applicationName: String,
        start: Date,
        duration: TimeInterval?
    ) -> ActivitySession {
        ActivitySession(
            applicationBundleIdentifier: "test.\(applicationName.lowercased())",
            applicationName: applicationName,
            startedAt: start,
            endedAt: duration.map { start.addingTimeInterval($0) }
        )
    }
}

@MainActor
private struct AnalyticsSessionStoreStub: ActivitySessionStore {
    let sessions: [ActivitySession]

    func fetchSessions(for range: AnalyticsRange) async throws -> [ActivitySession] {
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
}
