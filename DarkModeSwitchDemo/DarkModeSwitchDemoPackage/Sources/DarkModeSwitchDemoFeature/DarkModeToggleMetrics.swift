import CoreGraphics

struct DarkModeToggleMetrics: Sendable {
    static let trackArtboard = CGSize(width: 173, height: 69)
    static let celestialArtboard = CGSize(width: 173, height: 84)
    static let referenceComponentSize = CGSize(width: 130, height: 80)
    static let celestialWidthMultiplier: CGFloat = 1.2
    static let lightTranslationX: CGFloat = -100
    static let darkTranslationX: CGFloat = -25

    let width: CGFloat

    var componentHeight: CGFloat {
        width * Self.referenceComponentSize.height / Self.referenceComponentSize.width
    }

    var trackScale: CGFloat {
        width / Self.trackArtboard.width
    }

    var trackHeight: CGFloat {
        Self.trackArtboard.height * trackScale
    }

    var celestialScale: CGFloat {
        width * Self.celestialWidthMultiplier / Self.celestialArtboard.width
    }

    var celestialHeight: CGFloat {
        Self.celestialArtboard.height * celestialScale
    }

    var celestialVerticalInset: CGFloat {
        (componentHeight - celestialHeight) / 2
    }

    var translationTravel: CGFloat {
        (Self.darkTranslationX - Self.lightTranslationX) * celestialScale
    }

    func translationX(isDarkMode: Bool) -> CGFloat {
        (isDarkMode ? Self.darkTranslationX : Self.lightTranslationX) * celestialScale
    }
}
