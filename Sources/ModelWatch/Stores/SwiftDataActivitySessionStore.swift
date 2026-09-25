import Foundation
import SwiftData

@MainActor
struct SwiftDataActivitySessionStore: ActivitySessionStore {
    let context: ModelContext

    func fetchSessions(overlapping interval: DateInterval) async throws -> [ActivitySession] {
        let startDate = interval.start
        let endDate = interval.end
        let predicate = #Predicate<ActivitySession> { session in
            session.startedAt < endDate && (session.endedAt == nil || session.endedAt! > startDate)
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func save(_ session: ActivitySession) async throws {
        context.insert(session)
        try context.save()
    }

    func fetchUnfinishedSessions() async throws -> [ActivitySession] {
        let predicate = #Predicate<ActivitySession> { session in
            session.endedAt == nil
        }
        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func update(_ session: ActivitySession) async throws {
        try context.save()
    }

    func delete(_ session: ActivitySession) async throws {
        context.delete(session)
        try context.save()
    }
}
