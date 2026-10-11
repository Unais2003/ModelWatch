import SwiftUI
import SwiftData

@main
struct ModelWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appContainer = AppContainer.live()
    @AppStorage(AppPreferenceKey.showMenuBarStatus) private var showMenuBarStatus = true

    var body: some Scene {
        WindowGroup(AppConstants.appName, id: AppWindowID.dashboard.rawValue) {
            DashboardView(
                viewModel: DashboardViewModel(
                    analyticsService: appContainer.analyticsService,
                    subscriptionService: appContainer.subscriptionService,
                    activityTrackingService: appContainer.activityTrackingService,
                    dataManagementService: appContainer.dataManagementService
                )
            )
            .onAppear {
                appDelegate.activityTrackingService = appContainer.activityTrackingService
            }
            .modelContainer(appContainer.modelContainer)
        }
        .defaultSize(width: 980, height: 640)
        .commands {
            ModelWatchCommands()
        }

        MenuBarExtra(
            AppConstants.appName,
            systemImage: "chart.bar.xaxis",
            isInserted: $showMenuBarStatus
        ) {
            MenuBarView(
                viewModel: MenuBarViewModel(
                    activityTrackingService: appContainer.activityTrackingService
                )
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                viewModel: SettingsViewModel(
                    activityTrackingService: appContainer.activityTrackingService,
                    dataManagementService: appContainer.dataManagementService,
                    launchAtLoginService: appContainer.launchAtLoginService
                )
            )
        }
    }
}
