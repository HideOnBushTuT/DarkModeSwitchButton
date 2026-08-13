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

@Suite("Dark mode toggle source artwork")
struct DarkModeToggleArtTests {
    @Test("preserves all source cloud groups")
    func sourceClouds() {
        let groups = DarkModeToggleArt.cloudGroups

        #expect(groups.count == 4)
        #expect(groups.allSatisfy { $0.circles.count == 6 })
        #expect(groups.map(\.duration) == [3.5, 4.5, 2.5, 5.5])
        #expect(groups.map(\.opacity) == [0.95, 0.95, 0.6, 0.6])
        #expect(groups[0].circles[0] == ArtCircle(x: 94.2504, y: 60.8421, radius: 13.65))
        #expect(groups[3].circles[5] == ArtCircle(x: 105.433, y: 60.3442, radius: 13.65))
    }

    @Test("preserves all source stars and twinkle timings")
    func sourceStars() {
        let stars = DarkModeToggleArt.stars

        #expect(stars.count == 22)
        #expect(stars.filter { $0.group == 0 }.count == 2)
        #expect(DarkModeToggleArt.starDurations == [1: 3, 2: 2, 3: 1, 4: 5])
        #expect(stars[0] == ArtStar(group: 1, x: 16.95, y: 23.45, radius: 1.95))
        #expect(stars[19] == ArtStar(group: 1, x: 83.25, y: 39.05, radius: 0.65))
        #expect(stars.last == ArtStar(group: 3, x: 45.55, y: 26.05, radius: 0.65))
    }
}
