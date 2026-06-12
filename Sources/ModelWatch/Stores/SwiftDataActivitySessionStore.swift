import Foundation
import SwiftData

@MainActor
struct SwiftDataActivitySessionStore: ActivitySessionStore {
    let context: ModelContext

    func fetchSessions(for range: AnalyticsRange) async throws -> [ActivitySession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch range {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        }

        let predicate = #Predicate<ActivitySession> { session in
            session.startedAt >= startDate
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func save(_ session: ActivitySession) async throws {
        context.insert(session)
        try context.save()
    }
}
