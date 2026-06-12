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
            let context = ModelContext(modelContainer)

            SampleData.seedIfNeeded(context: context)

            let sessionStore = SwiftDataActivitySessionStore(context: context)
            let subscriptionStore = SwiftDataSubscriptionStore(context: context)

            return AppContainer(
                modelContainer: modelContainer,
                activityTrackingService: NoOpActivityTrackingService(),
                analyticsService: StoreBasedAnalyticsService(sessionStore: sessionStore),
                subscriptionService: StoreBasedSubscriptionService(subscriptionStore: subscriptionStore),
                notificationSchedulingService: NoOpNotificationSchedulingService()
            )
        } catch {
            fatalError("Failed to initialize ModelWatch persistence: \(error)")
        }
    }
}
