import SwiftUI

@MainActor
enum AppAppearanceOverride {
    static let environmentKey = "MODELWATCH_QA_APPEARANCE"

    static func colorScheme(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ColorScheme? {
        guard AppPerformanceProbe.isBenchmarkEnabled(environment: environment) else {
            return nil
        }

        switch environment[environmentKey]?.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
