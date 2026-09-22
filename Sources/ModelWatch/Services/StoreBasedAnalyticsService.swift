import Foundation

@MainActor
struct StoreBasedAnalyticsService: AnalyticsService {
    let sessionStore: any ActivitySessionStore

    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary {
        let sessions = try await sessionStore.fetchSessions(for: range)
        var totalDuration: TimeInterval = 0
        var applicationNames: Set<String> = []

        for session in sessions {
            guard let duration = completedDuration(for: session) else { continue }
            totalDuration += duration
            applicationNames.insert(session.applicationName)
        }

        return UsageSummary(
            range: range,
            totalDuration: totalDuration,
            trackedApplicationCount: applicationNames.count
        )
    }

    func usageByApplication(for range: AnalyticsRange) async throws -> [AppUsage] {
        let sessions = try await sessionStore.fetchSessions(for: range)
        var durations: [String: TimeInterval] = [:]

        for session in sessions {
            guard let duration = completedDuration(for: session) else { continue }
            durations[session.applicationName, default: 0] += duration
        }

        return durations
            .map { AppUsage(applicationName: $0.key, duration: $0.value) }
            .sorted { $0.duration > $1.duration }
    }

    private func completedDuration(for session: ActivitySession) -> TimeInterval? {
        guard let endedAt = session.endedAt else { return nil }

        let duration = endedAt.timeIntervalSince(session.startedAt)
        return duration > 0 ? duration : nil
    }
}
