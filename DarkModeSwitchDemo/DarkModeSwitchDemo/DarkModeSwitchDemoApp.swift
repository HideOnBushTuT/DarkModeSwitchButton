import SwiftUI

@main
struct DarkModeSwitchDemoApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-light-mode") {
            UserDefaults.standard.set(false, forKey: "isDarkMode")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
