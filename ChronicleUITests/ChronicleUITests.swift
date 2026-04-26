import XCTest

final class ChronicleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSmokeFlowInLightAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launchEnvironment["CHRONICLE_USE_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CHRONICLE_TEST_COLOUR_SCHEME"] = "light"
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Optical"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Hearing"].exists)
        XCTAssertTrue(app.tabBars.buttons["Sleep"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        XCTAssertTrue(app.navigationBars["Optical"].waitForExistence(timeout: 5))

        app.buttons["add-record-button"].tap()
        XCTAssertTrue(app.navigationBars["New prescription"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Hearing"].tap()
        XCTAssertTrue(app.navigationBars["Hearing"].waitForExistence(timeout: 5))

        app.buttons["add-hearing-test-button"].tap()
        XCTAssertTrue(app.navigationBars["New hearing test"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Sleep"].tap()
        XCTAssertTrue(app.navigationBars["Sleep"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testSmokeFlowInDarkAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launchEnvironment["CHRONICLE_USE_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CHRONICLE_TEST_COLOUR_SCHEME"] = "dark"
        app.launch()

        app.tabBars.buttons["Optical"].tap()
        XCTAssertTrue(app.navigationBars["Optical"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Hearing"].tap()
        XCTAssertTrue(app.navigationBars["Hearing"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Sleep"].tap()
        XCTAssertTrue(app.navigationBars["Sleep"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
