import SwiftUI

struct DayScene: View {
    let reduceMotion: Bool

    @State private var cloudsAreRaised = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / DarkModeToggleMetrics.trackArtboard.width

            ZStack(alignment: .topLeading) {
                TogglePalette.daySky

                ForEach(Array(DarkModeToggleArt.cloudGroups.enumerated()), id: \.offset) { _, group in
                    CloudGroupView(group: group)
                        .opacity(group.opacity)
                        .offset(y: cloudOffset(for: scale))
                        .animation(cloudAnimation(for: group), value: cloudsAreRaised)
                }
            }
            .onAppear {
                cloudsAreRaised = true
            }
        }
    }

    private func cloudOffset(for scale: CGFloat) -> CGFloat {
        guard !reduceMotion else { return 0 }
        return (cloudsAreRaised ? -10 : 5) * scale
    }

    private func cloudAnimation(for group: CloudGroup) -> Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.25, 0.46, 0.45, 0.94, duration: group.duration)
            .repeatForever(autoreverses: true)
    }
}

private struct CloudGroupView: View {
    let group: CloudGroup

    var body: some View {
        Canvas { context, size in
            let scale = size.width / DarkModeToggleMetrics.trackArtboard.width

            for circle in group.circles {
                let radius = CGFloat(circle.radius) * scale
                let rect = CGRect(
                    x: CGFloat(circle.x) * scale - radius,
                    y: CGFloat(circle.y) * scale - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
    }
}
