import XCTest
@testable import ModelWatch

@MainActor
final class AppPerformanceProbeTests: XCTestCase {
    func testBenchmarkModeRequiresExplicitEnvironmentValue() {
        XCTAssertTrue(
            AppPerformanceProbe.isBenchmarkEnabled(
                environment: [AppPerformanceProbe.benchmarkEnvironmentKey: "1"]
            )
        )
        XCTAssertFalse(
            AppPerformanceProbe.isBenchmarkEnabled(
                environment: [AppPerformanceProbe.benchmarkEnvironmentKey: "true"]
            )
        )
        XCTAssertFalse(AppPerformanceProbe.isBenchmarkEnabled(environment: [:]))
    }

    func testDurationIsReportedInMillisecondsAndNeverNegative() {
        XCTAssertEqual(
            AppPerformanceProbe.durationMilliseconds(from: 10, to: 10.25),
            250,
            accuracy: 0.001
        )
        XCTAssertEqual(
            AppPerformanceProbe.durationMilliseconds(from: 10, to: 9),
            0
        )
    }
}
