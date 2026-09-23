import Foundation

@MainActor
protocol ActivityTrackingPreferencesStore: AnyObject {
    var isMonitoringEnabled: Bool { get set }
    var trackedApplications: [TrackedApplication] { get set }
}

@MainActor
final class UserDefaultsActivityTrackingPreferencesStore: ActivityTrackingPreferencesStore {
    private enum Key {
        static let isMonitoringEnabled = "activityTracking.isMonitoringEnabled"
        static let trackedApplications = "activityTracking.trackedApplications"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isMonitoringEnabled: Bool {
        get { defaults.bool(forKey: Key.isMonitoringEnabled) }
        set { defaults.set(newValue, forKey: Key.isMonitoringEnabled) }
    }

    var trackedApplications: [TrackedApplication] {
        get {
            guard let data = defaults.data(forKey: Key.trackedApplications),
                  let applications = try? decoder.decode([TrackedApplication].self, from: data)
            else {
                return []
            }

            return applications.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
        set {
            let uniqueApplications = Dictionary(
                newValue.map { ($0.bundleIdentifier, $0) },
                uniquingKeysWith: { _, latest in latest }
            )
            let sortedApplications = uniqueApplications.values.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            guard let data = try? encoder.encode(sortedApplications) else { return }
            defaults.set(data, forKey: Key.trackedApplications)
        }
    }
}

