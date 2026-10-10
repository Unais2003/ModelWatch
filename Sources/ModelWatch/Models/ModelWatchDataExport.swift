import Foundation

struct ModelWatchDataExport: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let exportedAt: Date
    let activitySessions: [ActivitySessionRecord]
    let subscriptions: [SubscriptionRecord]

    struct ActivitySessionRecord: Codable, Equatable, Sendable {
        let id: UUID
        let applicationBundleIdentifier: String
        let applicationName: String
        let startedAt: Date
        let endedAt: Date?
    }

    struct SubscriptionRecord: Codable, Equatable, Sendable {
        let id: UUID
        let serviceName: String
        let monthlyCost: Double
        let currencyCode: String
        let renewalDate: Date?
        let isActive: Bool
    }
}
