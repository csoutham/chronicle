import XCTest

final class ChronicleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSmokeFlowInLightAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launchEnvironment["CHRONICLE_TEST_COLOUR_SCHEME"] = "light"
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Charts"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)

        app.buttons["add-record-button"].tap()
        XCTAssertTrue(app.navigationBars["New prescription"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Charts"].tap()
        XCTAssertTrue(app.segmentedControls["metric-picker"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testSmokeFlowInDarkAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launchEnvironment["CHRONICLE_TEST_COLOUR_SCHEME"] = "dark"
        app.launch()

        app.tabBars.buttons["Charts"].tap()
        XCTAssertTrue(app.navigationBars["Charts"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
