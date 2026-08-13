import SwiftUI

enum TogglePalette {
    static let daySky = Color(red: 162 / 255, green: 209 / 255, blue: 253 / 255)
    static let nightSky = Color(red: 31 / 255, green: 37 / 255, blue: 51 / 255)
    static let sun = Color(red: 255 / 255, green: 193 / 255, blue: 135 / 255)
    static let moon = Color(red: 222 / 255, green: 229 / 255, blue: 243 / 255)
    static let star = moon
}

public struct DarkModeToggle: View {
    @Binding private var isDarkMode: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isDarkMode: Binding<Bool>) {
        _isDarkMode = isDarkMode
    }

    public var body: some View {
        Button {
            isDarkMode.toggle()
        } label: {
            GeometryReader { proxy in
                let metrics = DarkModeToggleMetrics(width: proxy.size.width)

                ZStack(alignment: .topLeading) {
                    ToggleTrack(
                        isDarkMode: isDarkMode,
                        metrics: metrics,
                        reduceMotion: reduceMotion
                    )
                    .offset(y: (metrics.componentHeight - metrics.trackHeight) / 2)

                    CelestialThumb(
                        isDarkMode: isDarkMode,
                        metrics: metrics,
                        reduceMotion: reduceMotion
                    )
                }
                .frame(
                    width: metrics.width,
                    height: metrics.componentHeight,
                    alignment: .topLeading
                )
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(
            DarkModeToggleMetrics.referenceComponentSize.width
                / DarkModeToggleMetrics.referenceComponentSize.height,
            contentMode: .fit
        )
        .accessibilityLabel("Dark mode")
        .accessibilityValue(isDarkMode ? "Dark" : "Light")
        .accessibilityHint("Double tap to change appearance")
        .accessibilityIdentifier("darkModeToggle")
    }
}

private struct ToggleTrack: View {
    let isDarkMode: Bool
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool

    var body: some View {
        let scale = metrics.trackScale

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                .fill(isDarkMode ? TogglePalette.nightSky : TogglePalette.daySky)
                .overlay {
                    RoundedRectangle(cornerRadius: 33.15 * scale, style: .continuous)
                        .stroke(
                            borderGradient,
                            lineWidth: 1.3 * scale
                        )
                }
                .frame(width: 170.3 * scale, height: 66.3 * scale)
                .offset(x: 1.35 * scale, y: 1.35 * scale)

            ZStack(alignment: .topLeading) {
                DayScene(reduceMotion: reduceMotion)
                    .opacity(isDarkMode ? 0 : 1)

                NightScene(reduceMotion: reduceMotion)
                    .opacity(isDarkMode ? 1 : 0)
            }
            .animation(crossfadeAnimation, value: isDarkMode)
            .mask(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 32.5 * scale, style: .continuous)
                    .frame(width: 169 * scale, height: 65 * scale)
                    .offset(x: 2 * scale, y: 2 * scale)
            }

            RoundedRectangle(cornerRadius: 32.5 * scale, style: .continuous)
                .strokeBorder(innerEdgeGradient, lineWidth: 3.2 * scale)
                .frame(width: 169 * scale, height: 65 * scale)
                .offset(x: 2 * scale, y: 2 * scale)
                .allowsHitTesting(false)
        }
        .frame(width: metrics.width, height: metrics.trackHeight, alignment: .topLeading)
        .drawingGroup()
    }

    private var crossfadeAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.5)
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color.black.opacity(0.65), Color.white.opacity(0.04)]
                : [Color(red: 108 / 255, green: 184 / 255, blue: 1), Color.white.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var innerEdgeGradient: LinearGradient {
        LinearGradient(
            colors: isDarkMode
                ? [Color.black.opacity(0.58), Color.clear, Color.white.opacity(0.04)]
                : [Color.white.opacity(0.2), Color.clear, Color(red: 114 / 255, green: 187 / 255, blue: 1).opacity(0.58)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Light") {
    @Previewable @State var isDarkMode = false

    DarkModeToggle(isDarkMode: $isDarkMode)
        .frame(width: 260)
        .padding()
}

#Preview("Dark") {
    @Previewable @State var isDarkMode = true

    DarkModeToggle(isDarkMode: $isDarkMode)
        .frame(width: 260)
        .padding()
        .background(Color(red: 83 / 255, green: 92 / 255, blue: 114 / 255))
}
