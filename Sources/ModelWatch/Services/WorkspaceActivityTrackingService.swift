import Foundation
import Observation

@Observable
@MainActor
final class WorkspaceActivityTrackingService: ActivityTrackingService {
    private enum Message {
        static let persistenceFailure = "Monitoring stopped because activity data could not be saved."
    }

    private(set) var state = ActivityTrackingState.inactive
    private(set) var isMonitoringEnabled: Bool
    private(set) var trackedApplications: [TrackedApplication]
    private(set) var analyticsRevision = 0

    @ObservationIgnored private let sessionStore: any ActivitySessionStore
    @ObservationIgnored private let preferencesStore: any ActivityTrackingPreferencesStore
    @ObservationIgnored private let eventSource: any WorkspaceActivityEventSource
    @ObservationIgnored private let dateProvider: any DateProvider
    @ObservationIgnored private var currentSession: ActivitySession?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false

    init(
        sessionStore: any ActivitySessionStore,
        preferencesStore: any ActivityTrackingPreferencesStore,
        eventSource: any WorkspaceActivityEventSource,
        dateProvider: any DateProvider
    ) {
        self.sessionStore = sessionStore
        self.preferencesStore = preferencesStore
        self.eventSource = eventSource
        self.dateProvider = dateProvider
        let storedApplications = preferencesStore.trackedApplications
        let storedMonitoringPreference = preferencesStore.isMonitoringEnabled
        trackedApplications = storedApplications
        isMonitoringEnabled = storedMonitoringPreference && !storedApplications.isEmpty

        if storedMonitoringPreference && storedApplications.isEmpty {
            preferencesStore.isMonitoringEnabled = false
        }
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        guard isMonitoringEnabled else {
            do {
                try await discardUnfinishedSessions()
                state = .inactive
            } catch {
                handlePersistenceFailure()
            }
            return
        }

        await beginMonitoring()
    }

    func prepareForTermination() async {
        guard hasStarted else { return }
        await stopEventProcessingAndCloseSession()
    }

    func setMonitoringEnabled(_ isEnabled: Bool) async {
        guard !isEnabled || !trackedApplications.isEmpty else { return }
        guard isMonitoringEnabled != isEnabled || !hasStarted else { return }

        isMonitoringEnabled = isEnabled
        preferencesStore.isMonitoringEnabled = isEnabled
        hasStarted = true

        if isEnabled {
            await beginMonitoring()
        } else {
            await stopMonitoring()
        }
    }

    func addTrackedApplication(_ application: TrackedApplication) async {
        trackedApplications.removeAll { $0.bundleIdentifier == application.bundleIdentifier }
        trackedApplications.append(application)
        sortAndPersistApplications()

        guard isMonitoringEnabled,
              currentSession == nil,
              eventSource.frontmostApplication?.bundleIdentifier == application.bundleIdentifier
        else {
            return
        }

        await processApplicationActivation(eventSource.frontmostApplication)
    }

    func removeTrackedApplication(bundleIdentifier: String) async {
        trackedApplications.removeAll { $0.bundleIdentifier == bundleIdentifier }
        sortAndPersistApplications()

        if trackedApplications.isEmpty, isMonitoringEnabled {
            await setMonitoringEnabled(false)
            return
        }

        guard currentSession?.applicationBundleIdentifier == bundleIdentifier else { return }

        do {
            try await closeCurrentSession(at: dateProvider.now)
            state = .monitoring()
        } catch {
            handlePersistenceFailure()
        }
    }

    func process(_ event: WorkspaceActivityEvent) async {
        guard isMonitoringEnabled else { return }

        switch event {
        case let .applicationActivated(application):
            await processApplicationActivation(application)
        case .willSleep, .sessionResignedActive:
            await suspendMonitoring()
        case .didWake, .sessionBecameActive:
            state = .monitoring()
            await processApplicationActivation(eventSource.frontmostApplication)
        case .willTerminate:
            await stopEventProcessingAndCloseSession()
        }
    }

    private func beginMonitoring() async {
        eventTask?.cancel()
        eventSource.stop()

        let events = eventSource.events()

        do {
            try await discardUnfinishedSessions()
            state = .monitoring()
            try await transition(to: eventSource.frontmostApplication, at: dateProvider.now)
        } catch {
            handlePersistenceFailure()
            return
        }

        eventTask = Task { [weak self] in
            for await event in events {
                guard let self, !Task.isCancelled else { return }
                await self.process(event)
            }
        }
    }

    private func stopMonitoring() async {
        eventTask?.cancel()
        eventTask = nil
        eventSource.stop()

        do {
            try await closeCurrentSession(at: dateProvider.now)
            state = .inactive
        } catch {
            handlePersistenceFailure()
        }
    }

    private func suspendMonitoring() async {
        do {
            try await closeCurrentSession(at: dateProvider.now)
            state = .inactive
        } catch {
            handlePersistenceFailure()
        }
    }

    private func stopEventProcessingAndCloseSession() async {
        eventSource.stop()

        do {
            try await closeCurrentSession(at: dateProvider.now)
            state = .inactive
        } catch {
            handlePersistenceFailure()
        }
    }

    private func processApplicationActivation(_ application: WorkspaceApplication?) async {
        do {
            try await transition(to: application, at: dateProvider.now)
        } catch {
            handlePersistenceFailure()
        }
    }

    private func transition(to application: WorkspaceApplication?, at date: Date) async throws {
        if let currentSession,
           currentSession.applicationBundleIdentifier == application?.bundleIdentifier {
            state = .monitoring(activeApplicationName: currentSession.applicationName)
            return
        }

        try await closeCurrentSession(at: date)

        guard let application,
              trackedApplications.contains(where: { $0.bundleIdentifier == application.bundleIdentifier })
        else {
            state = .monitoring()
            return
        }

        let session = ActivitySession(
            applicationBundleIdentifier: application.bundleIdentifier,
            applicationName: application.displayName,
            startedAt: date
        )
        try await sessionStore.save(session)
        analyticsRevision &+= 1
        currentSession = session
        state = .monitoring(activeApplicationName: application.displayName)
    }

    private func closeCurrentSession(at date: Date) async throws {
        guard let session = currentSession else { return }

        currentSession = nil

        guard date > session.startedAt else {
            try await sessionStore.delete(session)
            analyticsRevision &+= 1
            return
        }

        session.endedAt = date
        try await sessionStore.update(session)
        analyticsRevision &+= 1
    }

    private func discardUnfinishedSessions() async throws {
        let unfinishedSessions = try await sessionStore.fetchUnfinishedSessions()
        for session in unfinishedSessions {
            try await sessionStore.delete(session)
            analyticsRevision &+= 1
        }
    }

    private func sortAndPersistApplications() {
        trackedApplications.sort {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        preferencesStore.trackedApplications = trackedApplications
    }

    private func handlePersistenceFailure() {
        eventTask?.cancel()
        eventTask = nil
        eventSource.stop()
        currentSession = nil
        state = .failed(message: Message.persistenceFailure)
    }
}
