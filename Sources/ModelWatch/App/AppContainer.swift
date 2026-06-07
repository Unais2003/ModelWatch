import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let activityTrackingService: any ActivityTrackingService
    let analyticsService: any AnalyticsService
    let subscriptionService: any SubscriptionService
    let notificationSchedulingService: any NotificationSchedulingService

    static func live() -> AppContainer {
        do {
            let modelContainer = try ModelContainer(
                for: ActivitySession.self,
                Subscription.self
            )

            return AppContainer(
                modelContainer: modelContainer,
                activityTrackingService: NoOpActivityTrackingService(),
                analyticsService: NoOpAnalyticsService(),
                subscriptionService: NoOpSubscriptionService(),
                notificationSchedulingService: NoOpNotificationSchedulingService()
            )
        } catch {
            fatalError("Failed to initialize ModelWatch persistence: \(error)")
        }
    }
}
