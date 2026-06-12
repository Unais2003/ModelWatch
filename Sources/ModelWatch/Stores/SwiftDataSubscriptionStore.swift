import Foundation
import SwiftData

@MainActor
struct SwiftDataSubscriptionStore: SubscriptionStore {
    let context: ModelContext

    func fetchActiveSubscriptions() async throws -> [Subscription] {
        let predicate = #Predicate<Subscription> { subscription in
            subscription.isActive == true
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.serviceName)])
        return try context.fetch(descriptor)
    }

    func save(_ subscription: Subscription) async throws {
        context.insert(subscription)
        try context.save()
    }
}
