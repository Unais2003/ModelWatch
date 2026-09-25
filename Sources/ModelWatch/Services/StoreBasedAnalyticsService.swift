import Foundation

@MainActor
struct StoreBasedAnalyticsService: AnalyticsService {
    let sessionStore: any ActivitySessionStore
    let dateProvider: any DateProvider
    let calendar: Calendar

    init(
        sessionStore: any ActivitySessionStore,
        dateProvider: any DateProvider,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.sessionStore = sessionStore
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    init(sessionStore: any ActivitySessionStore) {
        self.init(
            sessionStore: sessionStore,
            dateProvider: SystemDateProvider(),
            calendar: .autoupdatingCurrent
        )
    }

    func analytics(for range: AnalyticsRange) async throws -> AnalyticsSnapshot {
        let now = dateProvider.now
        guard let interval = range.dateInterval(containing: now, calendar: calendar) else {
            return .empty(range: range)
        }

        let sessions = try await sessionStore.fetchSessions(overlapping: interval)
        let reportingEnd = min(interval.end, now)
        var usageByBundleIdentifier: [String: AggregatedUsage] = [:]

        for session in sessions {
            guard let duration = overlapDuration(
                for: session,
                intervalStart: interval.start,
                reportingEnd: reportingEnd
            ) else { continue }

            let existing = usageByBundleIdentifier[session.applicationBundleIdentifier]
            let latestName: String
            let latestStart: Date

            if let existing, existing.latestSessionStart > session.startedAt {
                latestName = existing.applicationName
                latestStart = existing.latestSessionStart
            } else {
                latestName = session.applicationName
                latestStart = session.startedAt
            }

            usageByBundleIdentifier[session.applicationBundleIdentifier] = AggregatedUsage(
                applicationName: latestName,
                latestSessionStart: latestStart,
                duration: (existing?.duration ?? 0) + duration
            )
        }

        let usage = usageByBundleIdentifier.map { bundleIdentifier, aggregate in
            AppUsage(
                applicationBundleIdentifier: bundleIdentifier,
                applicationName: aggregate.applicationName,
                duration: aggregate.duration
            )
        }
        .sorted {
            if $0.duration == $1.duration {
                return $0.applicationName.localizedStandardCompare($1.applicationName) == .orderedAscending
            }
            return $0.duration > $1.duration
        }

        return AnalyticsSnapshot(
            summary: UsageSummary(
                range: range,
                totalDuration: usage.reduce(0) { $0 + $1.duration },
                trackedApplicationCount: usage.count
            ),
            usageByApplication: usage
        )
    }

    private func overlapDuration(
        for session: ActivitySession,
        intervalStart: Date,
        reportingEnd: Date
    ) -> TimeInterval? {
        let start = max(session.startedAt, intervalStart)
        let end = min(session.endedAt ?? reportingEnd, reportingEnd)
        let duration = end.timeIntervalSince(start)
        return duration > 0 ? duration : nil
    }

    private struct AggregatedUsage {
        let applicationName: String
        let latestSessionStart: Date
        let duration: TimeInterval
    }
}
