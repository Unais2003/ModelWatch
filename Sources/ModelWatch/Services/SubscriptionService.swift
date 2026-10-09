@MainActor
protocol SubscriptionService {
    func subscriptions() async throws -> [Subscription]
    func create(_ input: SubscriptionInput) async throws -> Subscription
    func update(_ subscription: Subscription, with input: SubscriptionInput) async throws
    func setActive(_ isActive: Bool, for subscription: Subscription) async throws
    func delete(_ subscription: Subscription) async throws
}

struct NoOpSubscriptionService: SubscriptionService {
    func subscriptions() async throws -> [Subscription] {
        []
    }

    func create(_ input: SubscriptionInput) async throws -> Subscription {
        Subscription(
            serviceName: input.serviceName,
            monthlyCost: input.monthlyCost,
            currencyCode: input.currencyCode,
            renewalDate: input.renewalDate,
            isActive: input.isActive
        )
    }

    func update(_ subscription: Subscription, with input: SubscriptionInput) async throws {
    }

    func setActive(_ isActive: Bool, for subscription: Subscription) async throws {
    }

    func delete(_ subscription: Subscription) async throws {
    }
}
