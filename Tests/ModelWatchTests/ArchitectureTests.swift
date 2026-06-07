import XCTest
@testable import ModelWatch

final class ArchitectureTests: XCTestCase {
    func testNoOpActivityTrackingStartsInactive() {
        let service = NoOpActivityTrackingService()

        XCTAssertEqual(service.currentState(), .inactive)
    }

    func testNoOpAnalyticsReturnsEmptySummaryForRange() async throws {
        let service = NoOpAnalyticsService()

        let summary = try await service.usageSummary(for: .week)

        XCTAssertEqual(summary, .empty(range: .week))
    }

    func testNoOpSubscriptionsReturnEmptyCollection() async throws {
        let service = NoOpSubscriptionService()

        let subscriptions = try await service.activeSubscriptions()

        XCTAssertTrue(subscriptions.isEmpty)
    }
}
