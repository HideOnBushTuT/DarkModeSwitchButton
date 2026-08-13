import XCTest

final class DarkModeSwitchDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSystemModeUpdatesWhenDeviceAppearanceChangesWithoutRelaunch() throws {
        defer { XCUIDevice.shared.appearance = .light }
        let app = launchFollowingSystem(appearance: .light)

        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "Off")

        let followSystemButton = app.buttons["followSystemAppearanceButton"]
        XCTAssertTrue(followSystemButton.waitForExistence(timeout: 3))
        XCTAssertEqual(followSystemButton.value as? String, "On")

        XCUIDevice.shared.appearance = .dark

        waitForValue("On", on: app.buttons["darkModeToggle"])
        XCTAssertEqual(
            app.buttons["followSystemAppearanceButton"].value as? String,
            "On"
        )
    }

    @MainActor
    func testManualToggleExitsAndButtonRestoresDarkSystemMode() throws {
        let app = launchFollowingSystem(appearance: .dark)

        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "On")

        let followSystemButton = app.buttons["followSystemAppearanceButton"]
        XCTAssertTrue(followSystemButton.waitForExistence(timeout: 3))
        XCTAssertEqual(followSystemButton.value as? String, "On")

        toggle.tap()
        waitForValue("Off", on: app.buttons["darkModeToggle"])
        waitForValue("Off", on: app.buttons["followSystemAppearanceButton"])

        app.buttons["followSystemAppearanceButton"].tap()
        waitForValue("On", on: app.buttons["darkModeToggle"])
        waitForValue("On", on: app.buttons["followSystemAppearanceButton"])
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
    func testHorizontalDragCommitsOnceAndNextTapStillWorks() throws {
        let app = launchInLightMode()
        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))

        drag(
            toggle,
            from: CGVector(dx: 0.15, dy: 0.5),
            to: CGVector(dx: 1.1, dy: 0.5)
        )
        waitForValue("On", on: app.buttons["darkModeToggle"])

        app.buttons["darkModeToggle"].tap()
        waitForValue("Off", on: app.buttons["darkModeToggle"])
    }

    @MainActor
    func testHorizontalDragReversesAndVerticalDragDoesNotToggle() throws {
        let app = launchInLightMode()
        let toggle = app.buttons["darkModeToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))

        drag(
            toggle,
            from: CGVector(dx: 0.15, dy: 0.5),
            to: CGVector(dx: 1.1, dy: 0.5)
        )
        waitForValue("On", on: app.buttons["darkModeToggle"])

        drag(
            app.buttons["darkModeToggle"],
            from: CGVector(dx: 0.85, dy: 0.5),
            to: CGVector(dx: -0.1, dy: 0.5)
        )
        waitForValue("Off", on: app.buttons["darkModeToggle"])

        drag(
            app.buttons["darkModeToggle"],
            from: CGVector(dx: 0.5, dy: 0.5),
            to: CGVector(dx: 0.5, dy: 1.2)
        )
        XCTAssertEqual(app.buttons["darkModeToggle"].value as? String, "Off")
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
        XCUIDevice.shared.appearance = .light
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-light-mode"]
        app.launch()
        return app
    }

    @MainActor
    private func launchFollowingSystem(
        appearance: XCUIDevice.Appearance
    ) -> XCUIApplication {
        XCUIDevice.shared.appearance = appearance
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-system-mode"]
        app.launch()
        return app
    }

    @MainActor
    private func drag(
        _ element: XCUIElement,
        from startOffset: CGVector,
        to endOffset: CGVector
    ) {
        let start = element.coordinate(withNormalizedOffset: startOffset)
        let end = element.coordinate(withNormalizedOffset: endOffset)
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor
    private func waitForValue(_ value: String, on element: XCUIElement) {
        let predicate = NSPredicate(format: "value == %@", value)
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: 2)
    }
}
