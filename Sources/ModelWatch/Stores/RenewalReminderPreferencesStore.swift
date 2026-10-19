import Foundation

@MainActor
protocol RenewalReminderPreferencesStore: AnyObject {
    var isEnabled: Bool { get set }
}

@MainActor
final class InMemoryRenewalReminderPreferencesStore: RenewalReminderPreferencesStore {
    var isEnabled: Bool

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }
}

@MainActor
final class UserDefaultsRenewalReminderPreferencesStore: RenewalReminderPreferencesStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: AppPreferenceKey.renewalRemindersEnabled) }
        set { defaults.set(newValue, forKey: AppPreferenceKey.renewalRemindersEnabled) }
    }
}
