import XCTest
@testable import ModelWatch

final class AppConstantsTests: XCTestCase {
    func testVersionDescriptionIncludesMarketingAndBuildVersions() {
        let description = AppConstants.versionDescription(
            infoDictionary: [
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "7"
            ]
        )

        XCTAssertEqual(description, "0.1.0 (7)")
    }

    func testVersionDescriptionSupportsMissingBuildNumber() {
        let description = AppConstants.versionDescription(
            infoDictionary: ["CFBundleShortVersionString": "0.1.0"]
        )

        XCTAssertEqual(description, "0.1.0")
    }

    func testVersionDescriptionIdentifiesUnbundledDevelopmentBuild() {
        XCTAssertEqual(
            AppConstants.versionDescription(infoDictionary: nil),
            "Development build"
        )
    }
}
