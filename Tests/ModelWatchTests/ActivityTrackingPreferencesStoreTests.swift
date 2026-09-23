import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class ActivityTrackingPreferencesStoreTests: XCTestCase {
    func testPreferencesRoundTripMonitoringAndDeduplicatedApplications() throws {
        let suiteName = "ModelWatchTests.ActivityTrackingPreferences.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsActivityTrackingPreferencesStore(defaults: defaults)
        store.isMonitoringEnabled = true
        store.trackedApplications = [
            TrackedApplication(bundleIdentifier: "test.cursor", displayName: "Cursor"),
            TrackedApplication(bundleIdentifier: "test.chatgpt", displayName: "ChatGPT"),
            TrackedApplication(bundleIdentifier: "test.cursor", displayName: "Cursor Updated"),
        ]

        let reloadedStore = UserDefaultsActivityTrackingPreferencesStore(defaults: defaults)

        XCTAssertTrue(reloadedStore.isMonitoringEnabled)
        XCTAssertEqual(
            reloadedStore.trackedApplications,
            [
                TrackedApplication(bundleIdentifier: "test.chatgpt", displayName: "ChatGPT"),
                TrackedApplication(bundleIdentifier: "test.cursor", displayName: "Cursor Updated"),
            ]
        )
    }
}
