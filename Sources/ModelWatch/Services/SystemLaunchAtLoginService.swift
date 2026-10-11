import ServiceManagement

@MainActor
final class SystemLaunchAtLoginService: LaunchAtLoginService {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    var status: LaunchAtLoginStatus {
        Self.map(service.status)
    }

    func setEnabled(_ isEnabled: Bool) async throws {
        if isEnabled {
            guard status != .enabled else { return }
            try service.register()
        } else {
            guard status == .enabled || status == .requiresApproval else { return }
            try await service.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    static func map(_ status: SMAppService.Status) -> LaunchAtLoginStatus {
        switch status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }
}
