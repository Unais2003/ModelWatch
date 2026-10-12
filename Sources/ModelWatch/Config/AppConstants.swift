import Foundation

enum AppConstants {
    static let appName = "ModelWatch"
    static let bundleIdentifier = "com.modelwatch.app"
    static let minimumSystemVersion = "14.0"

    static var versionDescription: String {
        versionDescription(infoDictionary: Bundle.main.infoDictionary)
    }

    static func versionDescription(infoDictionary: [String: Any]?) -> String {
        guard let version = infoDictionary?["CFBundleShortVersionString"] as? String,
              !version.isEmpty
        else {
            return "Development build"
        }

        guard let build = infoDictionary?["CFBundleVersion"] as? String,
              !build.isEmpty
        else {
            return version
        }

        return "\(version) (\(build))"
    }
}
