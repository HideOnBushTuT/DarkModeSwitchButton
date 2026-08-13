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
