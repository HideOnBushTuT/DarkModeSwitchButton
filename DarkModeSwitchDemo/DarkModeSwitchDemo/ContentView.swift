import DarkModeSwitchDemoFeature
import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            DarkModeToggle(vividIsDarkMode: $isDarkMode)
                .frame(width: 260)
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
}

#Preview {
    ContentView()
}
