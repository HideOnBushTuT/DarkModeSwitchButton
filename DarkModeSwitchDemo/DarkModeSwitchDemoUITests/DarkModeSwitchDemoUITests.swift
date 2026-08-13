import XCTest

final class DarkModeSwitchDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testToggleChangesTheAppAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-light-mode"]
        app.launch()

        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "Light")

        toggle.tap()

        let updatedToggle = app.buttons["darkModeToggle"]
        let darkValue = NSPredicate(format: "value == %@", "Dark")
        expectation(for: darkValue, evaluatedWith: updatedToggle)
        waitForExpectations(timeout: 2)
    }
}
