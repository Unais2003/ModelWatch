import Foundation

@MainActor
protocol DataManagementService: AnyObject {
    var revision: Int { get }

    func summary() async throws -> LocalDataSummary
    func exportData() async throws -> Data
    func deleteActivityHistory() async throws
    func deleteSubscriptions() async throws
    func deleteAllData() async throws
}

@MainActor
final class NoOpDataManagementService: DataManagementService {
    let revision = 0

    func summary() async throws -> LocalDataSummary {
        .empty
    }

    func exportData() async throws -> Data {
        Data()
    }

    func deleteActivityHistory() async throws {
    }

    func deleteSubscriptions() async throws {
    }

    func deleteAllData() async throws {
    }
}
