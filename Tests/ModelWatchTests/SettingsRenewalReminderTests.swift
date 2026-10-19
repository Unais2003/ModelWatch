import XCTest
@testable import ModelWatch

@MainActor
final class SettingsRenewalReminderTests: XCTestCase {
    func testSuccessfulEnableUpdatesVisibleState() async {
        let service = RenewalReminderServiceStub()
        let viewModel = makeViewModel(service: service)

        let succeeded = await viewModel.updateRenewalRemindersEnabled(true)

        XCTAssertTrue(succeeded)
        XCTAssertTrue(viewModel.areRenewalRemindersEnabled)
        XCTAssertEqual(service.requestedValues, [true])
        XCTAssertNil(viewModel.renewalReminderError)
    }

    func testEnableFailureLeavesVisibleStateDisabledAndReportsError() async {
        let service = RenewalReminderServiceStub()
        service.shouldFail = true
        let viewModel = makeViewModel(service: service)

        let succeeded = await viewModel.updateRenewalRemindersEnabled(true)

        XCTAssertFalse(succeeded)
        XCTAssertFalse(viewModel.areRenewalRemindersEnabled)
        XCTAssertNotNil(viewModel.renewalReminderError)
        XCTAssertFalse(viewModel.isUpdatingRenewalReminders)
    }

    private func makeViewModel(
        service: any RenewalReminderService
    ) -> SettingsViewModel {
        SettingsViewModel(
            activityTrackingService: NoOpActivityTrackingService(),
            dataManagementService: NoOpDataManagementService(),
            launchAtLoginService: NoOpLaunchAtLoginService(),
            renewalReminderService: service
        )
    }
}

@MainActor
private final class RenewalReminderServiceStub: RenewalReminderService {
    var isEnabled = false
    var shouldFail = false
    private(set) var requestedValues: [Bool] = []

    func setEnabled(_ isEnabled: Bool) async throws {
        requestedValues.append(isEnabled)
        if shouldFail {
            throw RenewalReminderServiceError.authorizationDenied
        }
        self.isEnabled = isEnabled
    }

    func synchronize() async throws {
    }
}
