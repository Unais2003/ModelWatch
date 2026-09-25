import Foundation

@MainActor
protocol ActivitySessionStore {
    func fetchSessions(overlapping interval: DateInterval) async throws -> [ActivitySession]
    func fetchUnfinishedSessions() async throws -> [ActivitySession]
    func save(_ session: ActivitySession) async throws
    func update(_ session: ActivitySession) async throws
    func delete(_ session: ActivitySession) async throws
}
