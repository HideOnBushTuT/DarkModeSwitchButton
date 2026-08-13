import Testing
@testable import DarkModeSwitchDemoFeature

@Suite("Dark mode toggle metrics")
struct DarkModeToggleMetricsTests {
    @Test("matches the source component geometry at 130 points wide")
    func sourceGeometry() {
        let metrics = DarkModeToggleMetrics(width: 130)

        #expect(abs(metrics.componentHeight - 80) < 0.0001)
        #expect(abs(metrics.trackHeight - 51.84971098) < 0.0001)
        #expect(abs(metrics.celestialScale - (156.0 / 173.0)) < 0.0001)
        #expect(abs(metrics.celestialVerticalInset - 2.12716763) < 0.0001)
    }

    @Test("preserves the source light and dark translations")
    func sourceTranslations() {
        let metrics = DarkModeToggleMetrics(width: 130)

        #expect(abs(metrics.translationX(isDarkMode: false) - (-90.17341040)) < 0.0001)
        #expect(abs(metrics.translationX(isDarkMode: true) - (-22.54335260)) < 0.0001)
        #expect(abs(metrics.translationTravel - 67.63005780) < 0.0001)
    }
}
