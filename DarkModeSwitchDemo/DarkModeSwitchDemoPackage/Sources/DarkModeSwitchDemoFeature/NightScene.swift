import SwiftUI

struct NightScene: View {
    let reduceMotion: Bool

    @State private var starsAreVisible = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / DarkModeToggleMetrics.trackArtboard.width

            ZStack(alignment: .topLeading) {
                TogglePalette.nightSky

                StarGroupView(stars: stars(in: 0), scale: scale)

                ForEach(1...4, id: \.self) { group in
                    StarGroupView(stars: stars(in: group), scale: scale)
                        .opacity(starOpacity)
                        .animation(starAnimation(for: group), value: starsAreVisible)
                }
            }
            .onAppear {
                starsAreVisible = true
            }
        }
    }

    private var starOpacity: Double {
        reduceMotion ? 1 : (starsAreVisible ? 1 : 0)
    }

    private func stars(in group: Int) -> [ArtStar] {
        DarkModeToggleArt.stars.filter { $0.group == group }
    }

    private func starAnimation(for group: Int) -> Animation? {
        guard !reduceMotion, let duration = DarkModeToggleArt.starDurations[group] else {
            return nil
        }
        return .easeInOut(duration: duration).repeatForever(autoreverses: true)
    }
}

private struct StarGroupView: View {
    let stars: [ArtStar]
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                FourPointStar()
                    .fill(TogglePalette.star)
                    .frame(
                        width: CGFloat(star.radius * 2) * scale,
                        height: CGFloat(star.radius * 2) * scale
                    )
                    .blur(radius: CGFloat(star.blurRadius) * scale)
                    .position(
                        x: CGFloat(star.x) * scale,
                        y: CGFloat(star.y) * scale
                    )
            }
        }
    }
}
