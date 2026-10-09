import Foundation
import SwiftData

@MainActor
struct SwiftDataSubscriptionStore: SubscriptionStore {
    let context: ModelContext

    func fetchSubscriptions() async throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.serviceName)])
        return try context.fetch(descriptor)
    }

    func save(_ subscription: Subscription) async throws {
        context.insert(subscription)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func update(_ subscription: Subscription) async throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(_ subscription: Subscription) async throws {
        context.delete(subscription)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
