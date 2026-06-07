import Observation

@Observable
final class SettingsViewModel {
    let appName = AppConstants.appName
    let minimumSystemVersion = AppConstants.minimumSystemVersion
}
