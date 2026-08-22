import DarkModeSwitchDemoFeature
import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            VStack(spacing: 36) {
                toggleDemo("Original") {
                    DarkModeToggle(isDarkMode: $isDarkMode)
                        .accessibilityIdentifier("originalDarkModeToggle")
                }

                toggleDemo("Vivid") {
                    DarkModeToggle(vividIsDarkMode: $isDarkMode)
                }
            }
            .padding(32)
        }
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.5),
            value: isDarkMode
        )
        .preferredColorScheme(isDarkMode ? .dark : .light)
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
