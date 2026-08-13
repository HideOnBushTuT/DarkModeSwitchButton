import SwiftUI

struct CelestialThumb: View {
    let isDarkMode: Bool
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool

    var body: some View {
        let scale = metrics.celestialScale

        ZStack(alignment: .topLeading) {
            SunDisc(scale: scale)
                .opacity(isDarkMode ? 0 : 1)
                .animation(crossfadeAnimation, value: isDarkMode)

            MoonDisc(scale: scale)
                .opacity(isDarkMode ? 1 : 0)
                .animation(crossfadeAnimation, value: isDarkMode)
        }
        .frame(
            width: DarkModeToggleMetrics.celestialArtboard.width * scale,
            height: DarkModeToggleMetrics.celestialArtboard.height * scale,
            alignment: .topLeading
        )
        .offset(
            x: metrics.translationX(isDarkMode: isDarkMode),
            y: metrics.celestialVerticalInset
        )
        .animation(translationAnimation, value: isDarkMode)
        .allowsHitTesting(false)
    }

    private var crossfadeAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.5)
    }

    private var translationAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.25, 0.1, 0.25, 1, duration: 1)
    }
}

private struct SunDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.5537
    private let sourceY: CGFloat = 20.365
    private let sourceWidth: CGFloat = 45.4463
    private let sourceHeight: CGFloat = 43.635
    private let sourceRadius: CGFloat = 21.8175

    var body: some View {
        RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
            .fill(TogglePalette.sun.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.clear,
                                Color(red: 1, green: 0.63, blue: 0.29).opacity(0.68),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2.6 * scale
                    )
            }
            .frame(width: sourceWidth * scale, height: sourceHeight * scale)
            .shadow(
                color: TogglePalette.sun.opacity(0.6),
                radius: 5.85 * scale
            )
            .shadow(
                color: Color(red: 0.717, green: 0.717, blue: 0.717).opacity(0.35),
                radius: 2.6 * scale,
                x: -3.9 * scale,
                y: 6.5 * scale
            )
            .offset(x: sourceX * scale, y: sourceY * scale)
    }
}

private struct MoonDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.0674
    private let sourceY: CGFloat = 20.3278
    private let sourceWidth: CGFloat = 45.4426
    private let sourceHeight: CGFloat = 43.6315
    private let sourceRadius: CGFloat = 21.8158

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                .fill(TogglePalette.moon)
                .overlay {
                    RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color.clear,
                                    Color(red: 0.748, green: 0.75, blue: 0.754).opacity(0.58),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.6 * scale
                        )
                }
                .frame(width: sourceWidth * scale, height: sourceHeight * scale)
                .shadow(
                    color: Color(red: 0.717, green: 0.717, blue: 0.717).opacity(0.31),
                    radius: 9.75 * scale,
                    x: -3.9 * scale
                )
                .offset(x: sourceX * scale, y: sourceY * scale)

            MoonOcclusionShape()
                .fill(TogglePalette.nightSky.opacity(0.79))
                .opacity(0.9)
        }
        .frame(
            width: DarkModeToggleMetrics.celestialArtboard.width * scale,
            height: DarkModeToggleMetrics.celestialArtboard.height * scale,
            alignment: .topLeading
        )
    }
}

private struct MoonOcclusionShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / DarkModeToggleMetrics.celestialArtboard.width
        let scaleY = rect.height / DarkModeToggleMetrics.celestialArtboard.height

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scaleX, y: y * scaleY)
        }

        var path = Path()
        path.move(to: point(132.712, 22.837))
        path.addCurve(
            to: point(112.361, 35.1418),
            control1: point(123.768, 20.7837),
            control2: point(114.702, 26.2647)
        )
        path.addCurve(
            to: point(124.675, 55.4324),
            control1: point(109.965, 44.2237),
            control2: point(115.515, 53.3683)
        )
        path.addLine(to: point(125.016, 55.5092))
        path.addLine(to: point(125.658, 55.6541))
        path.addCurve(
            to: point(146.016, 43.0404),
            control1: point(134.701, 57.6918),
            control2: point(143.815, 52.0444)
        )
        path.addCurve(
            to: point(133.695, 23.0626),
            control1: point(148.211, 34.062),
            control2: point(142.702, 25.1306)
        )
        path.addLine(to: point(132.712, 22.837))
        path.closeSubpath()
        return path
    }
}
