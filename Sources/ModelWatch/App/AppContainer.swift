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

            let sessionStore = SwiftDataActivitySessionStore(context: context)
            let subscriptionStore = SwiftDataSubscriptionStore(context: context)
            let trackingPreferencesStore = UserDefaultsActivityTrackingPreferencesStore()
            let dateProvider = SystemDateProvider()
            let activityTrackingService = WorkspaceActivityTrackingService(
                sessionStore: sessionStore,
                preferencesStore: trackingPreferencesStore,
                eventSource: NSWorkspaceActivityEventSource(),
                dateProvider: dateProvider
            )

            Task {
                await activityTrackingService.start()
            }

            return AppContainer(
                modelContainer: modelContainer,
                activityTrackingService: activityTrackingService,
                analyticsService: StoreBasedAnalyticsService(
                    sessionStore: sessionStore,
                    dateProvider: dateProvider
                ),
                subscriptionService: StoreBasedSubscriptionService(subscriptionStore: subscriptionStore),
                notificationSchedulingService: NoOpNotificationSchedulingService()
            )
        } catch {
            fatalError("Failed to initialize ModelWatch persistence: \(error)")
        }
    }
}
