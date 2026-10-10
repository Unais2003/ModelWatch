import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class SettingsDataManagementTests: XCTestCase {
    func testLoadingAndDeletingDataUpdatesVisibleSummary() async {
        let service = SettingsDataManagementServiceStub(
            summary: LocalDataSummary(activitySessionCount: 4, subscriptionCount: 2)
        )
        let viewModel = SettingsViewModel(
            activityTrackingService: NoOpActivityTrackingService(),
            dataManagementService: service
        )

        await viewModel.loadLocalDataSummary()
        XCTAssertEqual(viewModel.localDataState, .loaded)
        XCTAssertEqual(viewModel.localDataSummary.activitySessionCount, 4)

        let deleted = await viewModel.deleteActivityHistory()

        XCTAssertTrue(deleted)
        XCTAssertEqual(service.deleteActivityCallCount, 1)
        XCTAssertEqual(viewModel.localDataSummary.activitySessionCount, 0)
        XCTAssertEqual(viewModel.localDataSummary.subscriptionCount, 2)
        XCTAssertNotNil(viewModel.dataOperationMessage)
    }

    func testFailedDeletionReportsErrorAndRefreshesSummary() async {
        let service = SettingsDataManagementServiceStub(
            summary: LocalDataSummary(activitySessionCount: 1, subscriptionCount: 1)
        )
        service.shouldFailDeletion = true
        let viewModel = SettingsViewModel(
            activityTrackingService: NoOpActivityTrackingService(),
            dataManagementService: service
        )
        await viewModel.loadLocalDataSummary()

        let deleted = await viewModel.deleteAllData()

        XCTAssertFalse(deleted)
        XCTAssertEqual(
            viewModel.localDataSummary,
            LocalDataSummary(activitySessionCount: 1, subscriptionCount: 1)
        )
        XCTAssertNotNil(viewModel.dataOperationError)
    }

    func testPreparingExportReturnsDocumentData() async {
        let expectedData = Data("{\"schemaVersion\":1}".utf8)
        let service = SettingsDataManagementServiceStub(
            summary: .empty,
            exportData: expectedData
        )
        let viewModel = SettingsViewModel(
            activityTrackingService: NoOpActivityTrackingService(),
            dataManagementService: service
        )

        let document = await viewModel.prepareExport()

        XCTAssertEqual(document?.data, expectedData)
        XCTAssertNil(viewModel.dataOperationError)
    }
}

@MainActor
private final class SettingsDataManagementServiceStub: DataManagementService {
    private(set) var revision = 0
    var currentSummary: LocalDataSummary
    var exportDataValue: Data
    var shouldFailDeletion = false
    private(set) var deleteActivityCallCount = 0

    init(summary: LocalDataSummary, exportData: Data = Data("{}".utf8)) {
        currentSummary = summary
        exportDataValue = exportData
    }

    func summary() async throws -> LocalDataSummary {
        currentSummary
    }

    func exportData() async throws -> Data {
        exportDataValue
    }

    func deleteActivityHistory() async throws {
        try failIfNeeded()
        deleteActivityCallCount += 1
        currentSummary = LocalDataSummary(
            activitySessionCount: 0,
            subscriptionCount: currentSummary.subscriptionCount
        )
        revision += 1
    }

    func deleteSubscriptions() async throws {
        try failIfNeeded()
        currentSummary = LocalDataSummary(
            activitySessionCount: currentSummary.activitySessionCount,
            subscriptionCount: 0
        )
        revision += 1
    }

    func deleteAllData() async throws {
        try failIfNeeded()
        currentSummary = .empty
        revision += 1
    }

    private func failIfNeeded() throws {
        if shouldFailDeletion {
            throw SettingsDataTestError.expected
        }
    }
}

private enum SettingsDataTestError: Error {
    case expected
}
