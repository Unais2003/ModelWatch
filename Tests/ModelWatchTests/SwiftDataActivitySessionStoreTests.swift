import Foundation
import SwiftData
import XCTest
@testable import ModelWatch

@MainActor
final class SwiftDataActivitySessionStoreTests: XCTestCase {
    func testFetchSessionsUsesHalfOpenOverlapSemantics() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ActivitySession.self,
            configurations: configuration
        )
        let store = SwiftDataActivitySessionStore(context: ModelContext(container))
        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 2_000)
        )

        let endingAtStart = session(start: 800, end: 1_000)
        let crossingStart = session(start: 900, end: 1_100)
        let inside = session(start: 1_500, end: 1_600)
        let active = session(start: 1_700, end: nil)
        let startingAtEnd = session(start: 2_000, end: 2_100)

        for session in [endingAtStart, crossingStart, inside, active, startingAtEnd] {
            try await store.save(session)
        }

        let result = try await store.fetchSessions(overlapping: interval)

        XCTAssertEqual(Set(result.map(\.id)), Set([crossingStart.id, inside.id, active.id]))
    }

    private func session(start: TimeInterval, end: TimeInterval?) -> ActivitySession {
        ActivitySession(
            applicationBundleIdentifier: "test.application",
            applicationName: "Test Application",
            startedAt: Date(timeIntervalSince1970: start),
            endedAt: end.map(Date.init(timeIntervalSince1970:))
        )
    }
}
