import XCTest

final class KindlingMemoryFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingOffersPermissionLightSamplePath() {
        let app = launch(screen: "onboarding")
        XCTAssertTrue(app.staticTexts["Remember where life happened."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Explore a sample first"].exists)
        XCTAssertTrue(app.staticTexts["Only the photos you choose"].exists)
    }

    func testAtlasDisplaysBundledSampleTrip() {
        let app = launch(screen: "atlas")
        XCTAssertTrue(app.navigationBars["Your Atlas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A Weekend in Lisbon"].waitForExistence(timeout: 5))
    }

    func testMemoriesLibraryContainsSampleTrip() {
        let app = launch(screen: "memories")
        XCTAssertTrue(app.navigationBars["Memories"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A Weekend in Lisbon"].waitForExistence(timeout: 5))
    }

    private func launch(screen: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["KINDLING_SCREEN"] = screen
        app.launch()
        return app
    }
}
