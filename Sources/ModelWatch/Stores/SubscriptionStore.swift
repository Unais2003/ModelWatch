@MainActor
protocol SubscriptionStore {
    func fetchSubscriptions() async throws -> [Subscription]
    func save(_ subscription: Subscription) async throws
    func update(_ subscription: Subscription) async throws
    func delete(_ subscription: Subscription) async throws
}
