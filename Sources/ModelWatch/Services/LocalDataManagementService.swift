import Foundation
import Observation

@Observable
@MainActor
final class LocalDataManagementService: DataManagementService {
    private(set) var revision = 0

    @ObservationIgnored private let sessionStore: any ActivitySessionStore
    @ObservationIgnored private let subscriptionStore: any SubscriptionStore
    @ObservationIgnored private let activityTrackingService: any ActivityTrackingService
    @ObservationIgnored private let dateProvider: any DateProvider

    init(
        sessionStore: any ActivitySessionStore,
        subscriptionStore: any SubscriptionStore,
        activityTrackingService: any ActivityTrackingService,
        dateProvider: any DateProvider
    ) {
        self.sessionStore = sessionStore
        self.subscriptionStore = subscriptionStore
        self.activityTrackingService = activityTrackingService
        self.dateProvider = dateProvider
    }

    func summary() async throws -> LocalDataSummary {
        let resolvedSessions = try await sessionStore.fetchAllSessions()
        let resolvedSubscriptions = try await subscriptionStore.fetchSubscriptions()
        return LocalDataSummary(
            activitySessionCount: resolvedSessions.count,
            subscriptionCount: resolvedSubscriptions.count
        )
    }

    func exportData() async throws -> Data {
        let exportedAt = dateProvider.now
        let resolvedSessions = try await sessionStore.fetchAllSessions()
        let resolvedSubscriptions = try await subscriptionStore.fetchSubscriptions()

        let export = ModelWatchDataExport(
            schemaVersion: 1,
            exportedAt: exportedAt,
            activitySessions: resolvedSessions.map {
                ModelWatchDataExport.ActivitySessionRecord(
                    id: $0.id,
                    applicationBundleIdentifier: $0.applicationBundleIdentifier,
                    applicationName: $0.applicationName,
                    startedAt: $0.startedAt,
                    endedAt: $0.endedAt
                )
            },
            subscriptions: resolvedSubscriptions.map {
                ModelWatchDataExport.SubscriptionRecord(
                    id: $0.id,
                    serviceName: $0.serviceName,
                    monthlyCost: $0.monthlyCost,
                    currencyCode: $0.currencyCode,
                    renewalDate: $0.renewalDate,
                    isActive: $0.isActive
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(export)
    }

    func deleteActivityHistory() async throws {
        try await activityTrackingService.deleteActivityHistory()
        revision &+= 1
    }

    func deleteSubscriptions() async throws {
        try await subscriptionStore.deleteAllSubscriptions()
        revision &+= 1
    }

    func deleteAllData() async throws {
        try await activityTrackingService.deleteActivityHistory()
        try await subscriptionStore.deleteAllSubscriptions()
        revision &+= 1
    }
}
