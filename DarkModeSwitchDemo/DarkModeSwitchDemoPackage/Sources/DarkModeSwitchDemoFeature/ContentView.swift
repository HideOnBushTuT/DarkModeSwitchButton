import SwiftUI

public struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            DarkModeToggle(isDarkMode: $isDarkMode)
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
            ? Color(red: 83 / 255, green: 92 / 255, blue: 114 / 255)
            : Color(red: 205 / 255, green: 231 / 255, blue: 1)
    }
}

#Preview {
    ContentView()
}
