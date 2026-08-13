# Follow System Appearance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a System/Light/Dark app appearance preference that follows iOS by default, preserves explicit choices, and leaves the `DarkModeToggle` package unchanged.

**Architecture:** Add a small app-owned enum that resolves a stored preference against SwiftUI's system `ColorScheme`, migrates the legacy Boolean, and bridges the result to the package's existing `Binding<Bool>`. `ContentView` remains the state owner and adds one app-level button for returning to System mode. A new unit-test target covers deterministic state behavior, while UI tests cover the real app integration and persistence.

**Tech Stack:** Swift 6.1, SwiftUI, `@AppStorage`, XCTest/XCUITest, Xcode project test targets, XcodeBuildMCP simulator workflows.

---

## Task 1: Add app unit-test infrastructure and write failing preference tests

**Files:**

- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/xcshareddata/xcschemes/DarkModeSwitchDemo.xcscheme`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemo.xctestplan`
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoTests/AppAppearancePreferenceTests.swift`

- [ ] **Step 1: Add a hosted `DarkModeSwitchDemoTests` unit-test target**

Add a file-system-synchronized `DarkModeSwitchDemoTests` group and a
`com.apple.product-type.bundle.unit-test` native target. Give it Sources,
Frameworks, and Resources phases; a dependency on `DarkModeSwitchDemo`; and
Debug/Release settings with these exact hosted-test values:

```text
BUNDLE_LOADER = "$(TEST_HOST)";
CODE_SIGN_STYLE = Automatic;
GENERATE_INFOPLIST_FILE = YES;
PRODUCT_BUNDLE_IDENTIFIER = com.example.DarkModeSwitchDemoTests;
PRODUCT_NAME = "$(TARGET_NAME)";
SWIFT_VERSION = 5.0;
TARGETED_DEVICE_FAMILY = 1;
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/DarkModeSwitchDemo.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DarkModeSwitchDemo";
```

Add the target to the shared scheme and to the test plan before the existing UI
test target so the unit tests run first.

- [ ] **Step 2: Write the failing unit tests against the desired API**

Create `AppAppearancePreferenceTests.swift`:

```swift
import SwiftUI
import XCTest
@testable import DarkModeSwitchDemo

final class AppAppearancePreferenceTests: XCTestCase {
    func testMissingAndUnknownValuesResolveToSystem() {
        XCTAssertEqual(AppAppearancePreference(storedRawValue: nil), .system)
        XCTAssertEqual(AppAppearancePreference(storedRawValue: "unexpected"), .system)
    }

    func testSystemPreferenceUsesCurrentSystemColorScheme() {
        XCTAssertFalse(
            AppAppearancePreference.system.isDark(systemColorScheme: .light)
        )
        XCTAssertTrue(
            AppAppearancePreference.system.isDark(systemColorScheme: .dark)
        )
        XCTAssertNil(AppAppearancePreference.system.preferredColorScheme)
    }

    func testManualPreferencesIgnoreCurrentSystemColorScheme() {
        XCTAssertFalse(
            AppAppearancePreference.light.isDark(systemColorScheme: .dark)
        )
        XCTAssertTrue(
            AppAppearancePreference.dark.isDark(systemColorScheme: .light)
        )
        XCTAssertEqual(AppAppearancePreference.light.preferredColorScheme, .light)
        XCTAssertEqual(AppAppearancePreference.dark.preferredColorScheme, .dark)
    }

    func testLegacyDarkValueMigratesAndIsRemoved() {
        withIsolatedDefaults { defaults in
            defaults.set(true, forKey: AppAppearancePreference.legacyStorageKey)

            AppAppearancePreference.migrateLegacyPreferenceIfNeeded(in: defaults)

            XCTAssertEqual(
                defaults.string(forKey: AppAppearancePreference.storageKey),
                AppAppearancePreference.dark.rawValue
            )
            XCTAssertNil(
                defaults.object(forKey: AppAppearancePreference.legacyStorageKey)
            )
        }
    }

    func testExistingNewPreferenceWinsDuringLegacyCleanup() {
        withIsolatedDefaults { defaults in
            defaults.set(
                AppAppearancePreference.system.rawValue,
                forKey: AppAppearancePreference.storageKey
            )
            defaults.set(true, forKey: AppAppearancePreference.legacyStorageKey)

            AppAppearancePreference.migrateLegacyPreferenceIfNeeded(in: defaults)

            XCTAssertEqual(
                defaults.string(forKey: AppAppearancePreference.storageKey),
                AppAppearancePreference.system.rawValue
            )
            XCTAssertNil(
                defaults.object(forKey: AppAppearancePreference.legacyStorageKey)
            )
        }
    }

    private func withIsolatedDefaults(
        _ body: (UserDefaults) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let suiteName = "AppAppearancePreferenceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults", file: file, line: line)
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
```

- [ ] **Step 3: Run the suite and verify the expected red state**

Run:

```bash
xcodebuildmcp simulator test \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-id F33E989C-EDBE-468E-98F0-2E78B85303DB \
  --configuration Debug \
  --derived-data-path DerivedData
```

Expected: compilation fails in `AppAppearancePreferenceTests.swift` because
`AppAppearancePreference` does not exist. Confirm the existing UI test source
still compiles before moving to implementation.

## Task 2: Implement and migrate the app-owned appearance preference

**Files:**

- Create: `DarkModeSwitchDemo/DarkModeSwitchDemo/AppAppearancePreference.swift`
- Test: `DarkModeSwitchDemo/DarkModeSwitchDemoTests/AppAppearancePreferenceTests.swift`

- [ ] **Step 1: Implement the minimal preference model**

Create `AppAppearancePreference.swift`:

```swift
import Foundation
import SwiftUI

enum AppAppearancePreference: String, Equatable {
    case system
    case light
    case dark

    static let storageKey = "appearancePreference"
    static let legacyStorageKey = "isDarkMode"

    init(storedRawValue: String?) {
        self = Self(rawValue: storedRawValue ?? "") ?? .system
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    func isDark(systemColorScheme: ColorScheme) -> Bool {
        switch self {
        case .system:
            systemColorScheme == .dark
        case .light:
            false
        case .dark:
            true
        }
    }

    static func migrateLegacyPreferenceIfNeeded(in defaults: UserDefaults) {
        defer { defaults.removeObject(forKey: legacyStorageKey) }

        guard defaults.string(forKey: storageKey) == nil,
              defaults.object(forKey: legacyStorageKey) != nil else {
            return
        }

        let migratedPreference: Self = defaults.bool(forKey: legacyStorageKey)
            ? .dark
            : .light
        defaults.set(migratedPreference.rawValue, forKey: storageKey)
    }
}
```

- [ ] **Step 2: Run the full suite and verify green**

Run the same XcodeBuildMCP simulator test command. Expected: 5 unit tests and
the 4 existing UI tests pass with 0 failures.

- [ ] **Step 3: Commit the tested state model and test target**

```bash
git add DarkModeSwitchDemo
git commit -m "feat(app): model system appearance preference"
```

## Task 3: Write failing app integration tests

**Files:**

- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift`

- [ ] **Step 1: Add System-mode launch coverage**

Add these tests and launch helper to the existing UI test class:

```swift
@MainActor
func testSystemModeUsesLightSystemAppearance() throws {
    let app = launchFollowingSystem(interfaceStyle: "Light")

    let toggle = app.buttons["darkModeToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 3))
    XCTAssertEqual(toggle.value as? String, "Off")

    let followSystemButton = app.buttons["followSystemAppearanceButton"]
    XCTAssertTrue(followSystemButton.waitForExistence(timeout: 3))
    XCTAssertEqual(followSystemButton.value as? String, "On")
}

@MainActor
func testManualToggleExitsAndButtonRestoresDarkSystemMode() throws {
    let app = launchFollowingSystem(interfaceStyle: "Dark")

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
private func launchFollowingSystem(interfaceStyle: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
        "--ui-testing-system-mode",
        "-AppleInterfaceStyle",
        interfaceStyle,
        "-AppleInterfaceStyleSwitchesAutomatically",
        "YES"
    ]
    app.launch()
    return app
}
```

- [ ] **Step 2: Run the suite and verify the expected red state**

Run the full simulator test command. Expected: the new tests fail because
`followSystemAppearanceButton` does not exist and the app still forces Light
from its legacy Boolean default.

## Task 4: Integrate the tri-state preference and Follow System control

**Files:**

- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemoApp.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift`
- Test: `DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift`

- [ ] **Step 1: Run migration and normalize UI-test launch state**

Replace the app initializer with:

```swift
init() {
    let defaults = UserDefaults.standard
    let arguments = ProcessInfo.processInfo.arguments

    if arguments.contains("--ui-testing-light-mode") {
        defaults.set(
            AppAppearancePreference.light.rawValue,
            forKey: AppAppearancePreference.storageKey
        )
    } else if arguments.contains("--ui-testing-system-mode") {
        defaults.set(
            AppAppearancePreference.system.rawValue,
            forKey: AppAppearancePreference.storageKey
        )
    }

    AppAppearancePreference.migrateLegacyPreferenceIfNeeded(in: defaults)
}
```

- [ ] **Step 2: Replace the Boolean storage with a tri-state binding bridge**

Use this state and binding inside `ContentView`:

```swift
@AppStorage(AppAppearancePreference.storageKey)
private var storedAppearance = AppAppearancePreference.system.rawValue
@Environment(\.colorScheme) private var systemColorScheme
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private var appearancePreference: AppAppearancePreference {
    AppAppearancePreference(storedRawValue: storedAppearance)
}

private var isDarkMode: Bool {
    appearancePreference.isDark(systemColorScheme: systemColorScheme)
}

private var isDarkModeBinding: Binding<Bool> {
    Binding(
        get: { isDarkMode },
        set: { newValue in
            storedAppearance = newValue
                ? AppAppearancePreference.dark.rawValue
                : AppAppearancePreference.light.rawValue
        }
    )
}
```

Pass `isDarkModeBinding` to `DarkModeToggle` and pass
`appearancePreference.preferredColorScheme` to `.preferredColorScheme`.

- [ ] **Step 3: Add the app-owned Follow System button**

Place the toggle and button in `VStack(spacing: 24)`. Add this button below the
toggle:

```swift
Button {
    storedAppearance = AppAppearancePreference.system.rawValue
} label: {
    Label(
        appearancePreference == .system
            ? "Following System"
            : "Use System Setting",
        systemImage: appearancePreference == .system
            ? "checkmark.circle.fill"
            : "circle.lefthalf.filled"
    )
}
.buttonStyle(.plain)
.font(.callout.weight(.semibold))
.foregroundStyle(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.7))
.padding(.horizontal, 16)
.padding(.vertical, 10)
.background(.ultraThinMaterial, in: Capsule())
.accessibilityIdentifier("followSystemAppearanceButton")
.accessibilityLabel("Follow System Appearance")
.accessibilityValue(appearancePreference == .system ? "On" : "Off")
```

Keep the existing screen colors and Reduce Motion timing driven by the resolved
`isDarkMode` Boolean.

- [ ] **Step 4: Run the full suite and verify green**

Run the XcodeBuildMCP simulator test command. Expected: 5 unit tests and 6 UI
tests pass with 0 failures. Confirm the existing drag, interruption,
persistence, and accessibility-value behavior still passes.

- [ ] **Step 5: Commit the UI integration**

```bash
git add DarkModeSwitchDemo
git commit -m "feat(app): follow the system appearance"
```

## Task 5: Update project documentation

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Replace the Boolean-only state-flow documentation**

Document the app-owned `AppAppearancePreference` and include this state flow:

```text
UserDefaults: system / light / dark
                ⇅ @AppStorage
ContentView + @Environment(\.colorScheme)
    ├── resolved Binding<Bool> ──→ DarkModeToggle
    ├── optional preferredColorScheme ──→ App appearance
    ├── resolved Bool ──→ demo background
    └── Follow System button ──→ system preference
```

State explicitly that a toggle interaction records an explicit Light/Dark
choice, the Follow System button restores live iOS tracking, and the package
remains unchanged.

- [ ] **Step 2: Verify documentation and commit**

Run `git diff --check` and inspect the README diff against the design spec.

```bash
git add README.md
git commit -m "docs(app): explain system appearance mode"
```

## Task 6: Full build and live system-change verification

**Files:**

- Verify only; no expected source changes.

- [ ] **Step 1: Run the complete automated test plan**

Run:

```bash
xcodebuildmcp simulator test \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-id F33E989C-EDBE-468E-98F0-2E78B85303DB \
  --configuration Debug \
  --derived-data-path DerivedData
```

Expected: all 11 tests pass with 0 failures.

- [ ] **Step 2: Run a separate compile-only build**

```bash
xcodebuildmcp simulator build \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-id F33E989C-EDBE-468E-98F0-2E78B85303DB \
  --configuration Debug \
  --derived-data-path DerivedData
```

Expected: build succeeds without compile errors.

- [ ] **Step 3: Verify a live system appearance change without relaunch**

Build and run the app, launch it with `--ui-testing-system-mode`, and use
XcodeBuildMCP simulator management to set Light appearance. Capture the UI
snapshot and verify `darkModeToggle` is `Off` and
`followSystemAppearanceButton` is `On`. Change the running simulator to Dark,
wait for the UI, and verify the same toggle becomes `On` without launching the
app again. Return the simulator to Light when finished.

- [ ] **Step 4: Review scope and working-tree cleanliness**

Run:

```bash
git diff origin/main...HEAD --check
git status --short --branch
git diff --stat origin/main...HEAD
```

Confirm no files under the package repository were changed, `Package.resolved`
still references the same package version, and every Issue #6 acceptance
criterion maps to a passing test or the live simulator check.
