enum LaunchAtLoginStatus: Equatable, Sendable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    var isRequested: Bool {
        self == .enabled || self == .requiresApproval
    }
}
