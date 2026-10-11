@MainActor
protocol LaunchAtLoginService: AnyObject {
    var status: LaunchAtLoginStatus { get }

    func setEnabled(_ isEnabled: Bool) async throws
    func openSystemSettings()
}

@MainActor
final class NoOpLaunchAtLoginService: LaunchAtLoginService {
    let status = LaunchAtLoginStatus.unavailable

    func setEnabled(_ isEnabled: Bool) async throws {
    }

    func openSystemSettings() {
    }
}
