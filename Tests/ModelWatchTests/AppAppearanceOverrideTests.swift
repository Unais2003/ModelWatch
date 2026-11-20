import SwiftUI
import XCTest
@testable import ModelWatch

@MainActor
final class AppAppearanceOverrideTests: XCTestCase {
    func testAppearanceOverrideRequiresBenchmarkIsolation() {
        XCTAssertNil(
            AppAppearanceOverride.colorScheme(
                environment: [AppAppearanceOverride.environmentKey: "dark"]
            )
        )
    }

    func testAppearanceOverrideAcceptsLightAndDarkCaseInsensitively() {
        XCTAssertEqual(
            AppAppearanceOverride.colorScheme(environment: environment(appearance: "LIGHT")),
            .light
        )
        XCTAssertEqual(
            AppAppearanceOverride.colorScheme(environment: environment(appearance: "dark")),
            .dark
        )
    }

    func testAppearanceOverrideRejectsMissingAndUnsupportedValues() {
        XCTAssertNil(
            AppAppearanceOverride.colorScheme(
                environment: [AppPerformanceProbe.benchmarkEnvironmentKey: "1"]
            )
        )
        XCTAssertNil(
            AppAppearanceOverride.colorScheme(environment: environment(appearance: "system"))
        )
    }

    private func environment(appearance: String) -> [String: String] {
        [
            AppPerformanceProbe.benchmarkEnvironmentKey: "1",
            AppAppearanceOverride.environmentKey: appearance,
        ]
    }
}
