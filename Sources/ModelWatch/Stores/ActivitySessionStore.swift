protocol ActivitySessionStore {
    func fetchSessions(for range: AnalyticsRange) async throws -> [ActivitySession]
    func save(_ session: ActivitySession) async throws
}
