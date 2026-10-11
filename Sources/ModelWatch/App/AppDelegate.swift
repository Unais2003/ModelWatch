import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var activityTrackingService: (any ActivityTrackingService)?

    private var isPreparingForTermination = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        guard Self.shouldOpenDashboardAtLaunch() else {
            DispatchQueue.main.async {
                NSApp.windows
                    .filter { $0.title == AppConstants.appName }
                    .forEach { $0.orderOut(nil) }
            }
            return
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    static func shouldOpenDashboardAtLaunch(
        defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.object(forKey: AppPreferenceKey.openDashboardAtLaunch) as? Bool ?? true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let activityTrackingService else { return .terminateNow }
        guard !isPreparingForTermination else { return .terminateLater }

        isPreparingForTermination = true
        Task { @MainActor [weak self] in
            await activityTrackingService.prepareForTermination()
            sender.reply(toApplicationShouldTerminate: true)
            self?.isPreparingForTermination = false
        }
        return .terminateLater
    }
}
