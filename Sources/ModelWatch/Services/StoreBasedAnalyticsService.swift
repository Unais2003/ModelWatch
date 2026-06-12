import Foundation

@MainActor
struct StoreBasedAnalyticsService: AnalyticsService {
    let sessionStore: any ActivitySessionStore

    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary {
        let sessions = try await sessionStore.fetchSessions(for: range)
        let totalDuration = sessions.reduce(0) { sum, session in
            guard let endedAt = session.endedAt else { return sum }
            return sum + endedAt.timeIntervalSince(session.startedAt)
        }
        let apps = Set(sessions.map(\.applicationName))
        return UsageSummary(range: range, totalDuration: totalDuration, trackedApplicationCount: apps.count)
    }

    func usageByApplication(for range: AnalyticsRange) async throws -> [AppUsage] {
        let sessions = try await sessionStore.fetchSessions(for: range)
        var durations: [String: TimeInterval] = [:]

        for session in sessions {
            guard let endedAt = session.endedAt else { continue }
            let duration = endedAt.timeIntervalSince(session.startedAt)
            durations[session.applicationName, default: 0] += duration
        }

        return durations
            .map { AppUsage(applicationName: $0.key, duration: $0.value) }
            .sorted { $0.duration > $1.duration }
    }
}
