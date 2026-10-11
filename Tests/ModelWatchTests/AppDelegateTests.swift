import Foundation
import Testing
@testable import ModelWatch

struct AppDelegateTests {
    @Test func opensDashboardByDefault() {
        let defaults = makeDefaults()

        #expect(AppDelegate.shouldOpenDashboardAtLaunch(defaults: defaults))
    }

    @Test func respectsDisabledDashboardPreference() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppPreferenceKey.openDashboardAtLaunch)

        #expect(!AppDelegate.shouldOpenDashboardAtLaunch(defaults: defaults))
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppDelegateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
