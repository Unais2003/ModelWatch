import SwiftUI
import SwiftData

@main
struct ModelWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appContainer = AppContainer.live()

    var body: some Scene {
        WindowGroup(AppConstants.appName, id: AppWindowID.dashboard.rawValue) {
            DashboardView(
                viewModel: DashboardViewModel(
                    analyticsService: appContainer.analyticsService,
                    subscriptionService: appContainer.subscriptionService
                )
            )
            .modelContainer(appContainer.modelContainer)
        }
        .defaultSize(width: 980, height: 640)
        .commands {
            ModelWatchCommands()
        }

        MenuBarExtra(AppConstants.appName, systemImage: "chart.bar.xaxis") {
            MenuBarView(
                viewModel: MenuBarViewModel(
                    activityTrackingService: appContainer.activityTrackingService
                )
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(viewModel: SettingsViewModel())
        }
    }
}
