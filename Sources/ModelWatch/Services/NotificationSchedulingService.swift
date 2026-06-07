protocol NotificationSchedulingService {
    func requestAuthorizationIfNeeded() async throws
}

struct NoOpNotificationSchedulingService: NotificationSchedulingService {
    func requestAuthorizationIfNeeded() async throws {
    }
}
