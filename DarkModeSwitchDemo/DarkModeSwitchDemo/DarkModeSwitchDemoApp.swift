import SwiftUI

@main
struct DarkModeSwitchDemoApp: App {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
