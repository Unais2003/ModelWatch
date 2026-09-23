import AppKit

struct WorkspaceApplication: Equatable, Sendable {
    let bundleIdentifier: String
    let displayName: String
}

enum WorkspaceActivityEvent: Equatable, Sendable {
    case applicationActivated(WorkspaceApplication?)
    case willSleep
    case didWake
    case sessionResignedActive
    case sessionBecameActive
    case willTerminate
}

@MainActor
protocol WorkspaceActivityEventSource: AnyObject {
    var frontmostApplication: WorkspaceApplication? { get }

    func events() -> AsyncStream<WorkspaceActivityEvent>
    func stop()
}

@MainActor
final class NSWorkspaceActivityEventSource: WorkspaceActivityEventSource {
    private let workspace: NSWorkspace
    private var workspaceObservers: [NSObjectProtocol] = []
    private var continuation: AsyncStream<WorkspaceActivityEvent>.Continuation?

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    var frontmostApplication: WorkspaceApplication? {
        Self.applicationIdentity(from: workspace.frontmostApplication)
    }

    func events() -> AsyncStream<WorkspaceActivityEvent> {
        stop()

        return AsyncStream { continuation in
            self.continuation = continuation
            self.startObserving()
        }
    }

    func stop() {
        let workspaceCenter = workspace.notificationCenter
        for observer in workspaceObservers {
            workspaceCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()

        continuation?.finish()
        continuation = nil
    }

    private func startObserving() {
        let center = workspace.notificationCenter

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: workspace,
                queue: .main
            ) { [weak self] notification in
                let runningApplication = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication
                let application = Self.applicationIdentity(from: runningApplication)
                MainActor.assumeIsolated {
                    _ = self?.continuation?.yield(.applicationActivated(application))
                }
            }
        )

        observeWorkspaceNotification(NSWorkspace.willSleepNotification, event: .willSleep)
        observeWorkspaceNotification(NSWorkspace.didWakeNotification, event: .didWake)
        observeWorkspaceNotification(
            NSWorkspace.sessionDidResignActiveNotification,
            event: .sessionResignedActive
        )
        observeWorkspaceNotification(
            NSWorkspace.sessionDidBecomeActiveNotification,
            event: .sessionBecameActive
        )
        observeWorkspaceNotification(NSWorkspace.willPowerOffNotification, event: .willTerminate)

    }

    private func observeWorkspaceNotification(
        _ name: Notification.Name,
        event: WorkspaceActivityEvent
    ) {
        workspaceObservers.append(
            workspace.notificationCenter.addObserver(
                forName: name,
                object: workspace,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    _ = self?.continuation?.yield(event)
                }
            }
        )
    }

    private nonisolated static func applicationIdentity(
        from application: NSRunningApplication?
    ) -> WorkspaceApplication? {
        guard let application,
              let bundleIdentifier = application.bundleIdentifier
        else {
            return nil
        }

        return WorkspaceApplication(
            bundleIdentifier: bundleIdentifier,
            displayName: application.localizedName ?? bundleIdentifier
        )
    }
}
