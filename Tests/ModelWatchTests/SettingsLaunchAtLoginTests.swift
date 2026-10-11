import XCTest
@testable import ModelWatch

@MainActor
final class SettingsLaunchAtLoginTests: XCTestCase {
    func testEnablingLaunchAtLoginRefreshesEnabledStatus() async {
        let service = LaunchAtLoginServiceStub(status: .disabled)
        let viewModel = makeViewModel(service: service)

        let succeeded = await viewModel.updateLaunchAtLoginEnabled(true)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(service.requestedValues, [true])
        XCTAssertEqual(viewModel.launchAtLoginStatus, .enabled)
        XCTAssertTrue(viewModel.isLaunchAtLoginRequested)
        XCTAssertNil(viewModel.launchAtLoginError)
    }

    func testRequiresApprovalRemainsRequestedAndOpensSystemSettings() {
        let service = LaunchAtLoginServiceStub(status: .requiresApproval)
        let viewModel = makeViewModel(service: service)

        viewModel.refreshLaunchAtLoginStatus()
        viewModel.openLoginItemsSettings()

        XCTAssertTrue(viewModel.isLaunchAtLoginRequested)
        XCTAssertTrue(viewModel.launchAtLoginStatusMessage.contains("Approval"))
        XCTAssertEqual(service.openSettingsCallCount, 1)
    }

    func testRegistrationFailureKeepsCurrentStatusAndReportsError() async {
        let service = LaunchAtLoginServiceStub(status: .disabled)
        service.shouldFail = true
        let viewModel = makeViewModel(service: service)

        let succeeded = await viewModel.updateLaunchAtLoginEnabled(true)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.launchAtLoginStatus, .disabled)
        XCTAssertNotNil(viewModel.launchAtLoginError)
        XCTAssertFalse(viewModel.isUpdatingLaunchAtLogin)
    }

    private func makeViewModel(service: any LaunchAtLoginService) -> SettingsViewModel {
        SettingsViewModel(
            activityTrackingService: NoOpActivityTrackingService(),
            dataManagementService: NoOpDataManagementService(),
            launchAtLoginService: service
        )
    }
}

@MainActor
private final class LaunchAtLoginServiceStub: LaunchAtLoginService {
    var status: LaunchAtLoginStatus
    var shouldFail = false
    private(set) var requestedValues: [Bool] = []
    private(set) var openSettingsCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func setEnabled(_ isEnabled: Bool) async throws {
        requestedValues.append(isEnabled)
        if shouldFail {
            throw LaunchAtLoginTestError.expected
        }
        status = isEnabled ? .enabled : .disabled
    }

    func openSystemSettings() {
        openSettingsCallCount += 1
    }
}

private enum LaunchAtLoginTestError: Error {
    case expected
}
