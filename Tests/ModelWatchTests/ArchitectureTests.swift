import XCTest
@testable import ModelWatch

@MainActor
final class ArchitectureTests: XCTestCase {
    func testNoOpActivityTrackingStartsInactive() {
        let service = NoOpActivityTrackingService()

        XCTAssertEqual(service.state, .inactive)
    }

    func testNoOpAnalyticsReturnsEmptySummaryForRange() async throws {
        let service = NoOpAnalyticsService()

        let snapshot = try await service.analytics(for: .week)

        XCTAssertEqual(snapshot, .empty(range: .week))
    }

    func testNoOpSubscriptionsReturnEmptyCollection() async throws {
        let service = NoOpSubscriptionService()

        let subscriptions = try await service.activeSubscriptions()

        XCTAssertTrue(subscriptions.isEmpty)
    }
}
