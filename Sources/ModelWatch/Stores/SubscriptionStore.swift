protocol SubscriptionStore {
    func fetchActiveSubscriptions() async throws -> [Subscription]
    func save(_ subscription: Subscription) async throws
}
