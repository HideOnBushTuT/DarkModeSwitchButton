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
