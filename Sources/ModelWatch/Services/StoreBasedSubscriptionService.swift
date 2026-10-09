import Foundation

@MainActor
struct StoreBasedSubscriptionService: SubscriptionService {
    let subscriptionStore: any SubscriptionStore

    func subscriptions() async throws -> [Subscription] {
        try await subscriptionStore.fetchSubscriptions().sorted(by: subscriptionSort)
    }

    func create(_ input: SubscriptionInput) async throws -> Subscription {
        let input = try validated(input)
        let subscription = Subscription(
            serviceName: input.serviceName,
            monthlyCost: input.monthlyCost,
            currencyCode: input.currencyCode,
            renewalDate: input.renewalDate,
            isActive: input.isActive
        )
        try await subscriptionStore.save(subscription)
        return subscription
    }

    func update(_ subscription: Subscription, with input: SubscriptionInput) async throws {
        let input = try validated(input)
        let previousInput = SubscriptionInput(
            serviceName: subscription.serviceName,
            monthlyCost: subscription.monthlyCost,
            currencyCode: subscription.currencyCode,
            renewalDate: subscription.renewalDate,
            isActive: subscription.isActive
        )

        apply(input, to: subscription)

        do {
            try await subscriptionStore.update(subscription)
        } catch {
            apply(previousInput, to: subscription)
            throw error
        }
    }

    func setActive(_ isActive: Bool, for subscription: Subscription) async throws {
        guard subscription.isActive != isActive else { return }

        let previousValue = subscription.isActive
        subscription.isActive = isActive

        do {
            try await subscriptionStore.update(subscription)
        } catch {
            subscription.isActive = previousValue
            throw error
        }
    }

    func delete(_ subscription: Subscription) async throws {
        try await subscriptionStore.delete(subscription)
    }

    private func validated(_ input: SubscriptionInput) throws -> SubscriptionInput {
        let serviceName = input.serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !serviceName.isEmpty else {
            throw SubscriptionValidationError.emptyServiceName
        }

        guard input.monthlyCost.isFinite, input.monthlyCost >= 0 else {
            throw SubscriptionValidationError.invalidMonthlyCost
        }

        let currencyCode = input.currencyCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard Locale.commonISOCurrencyCodes.contains(currencyCode) else {
            throw SubscriptionValidationError.unsupportedCurrencyCode
        }

        return SubscriptionInput(
            serviceName: serviceName,
            monthlyCost: input.monthlyCost,
            currencyCode: currencyCode,
            renewalDate: input.renewalDate,
            isActive: input.isActive
        )
    }

    private func apply(_ input: SubscriptionInput, to subscription: Subscription) {
        subscription.serviceName = input.serviceName
        subscription.monthlyCost = input.monthlyCost
        subscription.currencyCode = input.currencyCode
        subscription.renewalDate = input.renewalDate
        subscription.isActive = input.isActive
    }

    private func subscriptionSort(_ lhs: Subscription, _ rhs: Subscription) -> Bool {
        if lhs.isActive != rhs.isActive {
            return lhs.isActive
        }
        return lhs.serviceName.localizedStandardCompare(rhs.serviceName) == .orderedAscending
    }
}
