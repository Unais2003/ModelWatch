import ServiceManagement
import XCTest
@testable import ModelWatch

@MainActor
final class LaunchAtLoginServiceTests: XCTestCase {
    func testSystemStatusMappingCoversEveryKnownStatus() {
        XCTAssertEqual(SystemLaunchAtLoginService.map(.notRegistered), .disabled)
        XCTAssertEqual(SystemLaunchAtLoginService.map(.enabled), .enabled)
        XCTAssertEqual(SystemLaunchAtLoginService.map(.requiresApproval), .requiresApproval)
        XCTAssertEqual(SystemLaunchAtLoginService.map(.notFound), .unavailable)
    }
}
