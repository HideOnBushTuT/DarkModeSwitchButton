import DarkModeSwitchDemoFeature
import SwiftUI

struct ContentView: View {
    @AppStorage(AppAppearancePreference.storageKey)
    private var storedAppearance = AppAppearancePreference.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                toggleDemo("Original") {
                    DarkModeToggle(isDarkMode: isDarkModeBinding)
                        .accessibilityIdentifier("originalDarkModeToggle")
                }

                toggleDemo("Vivid") {
                    DarkModeToggle(vividIsDarkMode: isDarkModeBinding)
                }

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
                .foregroundStyle(labelColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .accessibilityIdentifier("followSystemAppearanceButton")
                .accessibilityLabel("Follow System Appearance")
                .accessibilityValue(
                    appearancePreference == .system ? "On" : "Off"
                )
            }
            .padding(32)
        }
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.5),
            value: isDarkMode
        )
        .preferredColorScheme(appearancePreference.preferredColorScheme)
    }

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

    private var screenBackground: Color {
        isDarkMode
            ? Color(red: 66 / 255, green: 66 / 255, blue: 66 / 255)
            : Color(red: 235 / 255, green: 246 / 255, blue: 1)
    }

    private var labelColor: Color {
        isDarkMode ? .white.opacity(0.82) : .black.opacity(0.68)
    }

    private func toggleDemo<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(labelColor)

            content()
                .frame(width: 260)
        }
    }
}

#Preview {
    ContentView()
}
