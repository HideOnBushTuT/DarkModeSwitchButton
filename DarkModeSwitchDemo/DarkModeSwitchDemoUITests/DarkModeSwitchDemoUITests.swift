import XCTest

final class DarkModeSwitchDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testToggleChangesAndReversesWhileAnimationIsInFlight() throws {
        let app = launchInLightMode()

        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.label, "Dark Mode")
        XCTAssertEqual(toggle.value as? String, "Off")

        toggle.tap()

        let updatedToggle = app.buttons["darkModeToggle"]
        waitForValue("On", on: updatedToggle)

        updatedToggle.tap()
        waitForValue("Off", on: app.buttons["darkModeToggle"])
    }

    @MainActor
    func testDarkModePersistsAcrossRelaunch() throws {
        let app = launchInLightMode()
        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))

        toggle.tap()
        waitForValue("On", on: app.buttons["darkModeToggle"])
        app.terminate()

        app.launchArguments = []
        app.launch()

        let persistedToggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(persistedToggle.waitForExistence(timeout: 3))
        XCTAssertEqual(persistedToggle.value as? String, "On")
    }

    @MainActor
    private func launchInLightMode() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-light-mode"]
        app.launch()
        return app
    }

    @MainActor
    private func waitForValue(_ value: String, on element: XCUIElement) {
        let predicate = NSPredicate(format: "value == %@", value)
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: 2)
    }
}
