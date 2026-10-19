import SwiftData

@MainActor
struct AppContainer {
    let modelContainer: ModelContainer
    let activityTrackingService: any ActivityTrackingService
    let analyticsService: any AnalyticsService
    let subscriptionService: any SubscriptionService
    let dataManagementService: any DataManagementService
    let launchAtLoginService: any LaunchAtLoginService
    let renewalReminderService: any RenewalReminderService

    static func live() -> AppContainer {
        live(isPerformanceBenchmark: AppPerformanceProbe.isBenchmarkEnabled())
    }

    static func live(isPerformanceBenchmark: Bool) -> AppContainer {
        do {
            let modelContainer: ModelContainer
            if isPerformanceBenchmark {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: ActivitySession.self,
                    Subscription.self,
                    configurations: configuration
                )
            } else {
                modelContainer = try ModelContainer(
                    for: ActivitySession.self,
                    Subscription.self
                )
            }
            let context = ModelContext(modelContainer)

            let sessionStore = SwiftDataActivitySessionStore(context: context)
            let subscriptionStore = SwiftDataSubscriptionStore(context: context)
            let trackingPreferencesStore: any ActivityTrackingPreferencesStore =
                isPerformanceBenchmark
                ? InMemoryActivityTrackingPreferencesStore()
                : UserDefaultsActivityTrackingPreferencesStore()
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

            let renewalReminderService: any RenewalReminderService
            if isPerformanceBenchmark {
                renewalReminderService = NoOpRenewalReminderService()
            } else {
                renewalReminderService = LocalRenewalReminderService(
                    subscriptionStore: subscriptionStore,
                    preferencesStore: UserDefaultsRenewalReminderPreferencesStore(),
                    notificationService: SystemNotificationSchedulingService(
                        dateProvider: dateProvider
                    ),
                    dateProvider: dateProvider
                )
            }

            return AppContainer(
                modelContainer: modelContainer,
                activityTrackingService: activityTrackingService,
                analyticsService: StoreBasedAnalyticsService(
                    sessionStore: sessionStore,
                    dateProvider: dateProvider
                ),
                subscriptionService: StoreBasedSubscriptionService(subscriptionStore: subscriptionStore),
                dataManagementService: LocalDataManagementService(
                    sessionStore: sessionStore,
                    subscriptionStore: subscriptionStore,
                    activityTrackingService: activityTrackingService,
                    dateProvider: dateProvider
                ),
                launchAtLoginService: SystemLaunchAtLoginService(),
                renewalReminderService: renewalReminderService
            )
        } catch {
            fatalError("Failed to initialize ModelWatch persistence: \(error)")
        }
    }
}
