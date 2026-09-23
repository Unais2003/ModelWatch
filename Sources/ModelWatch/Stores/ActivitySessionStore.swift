@MainActor
protocol ActivitySessionStore {
    func fetchSessions(for range: AnalyticsRange) async throws -> [ActivitySession]
    func fetchUnfinishedSessions() async throws -> [ActivitySession]
    func save(_ session: ActivitySession) async throws
    func update(_ session: ActivitySession) async throws
    func delete(_ session: ActivitySession) async throws
}
