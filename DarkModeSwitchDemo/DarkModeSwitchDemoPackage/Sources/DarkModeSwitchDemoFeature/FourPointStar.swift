import SwiftUI

struct FourPointStar: Shape {
    private let innerRadiusRatio: CGFloat = 0.2701

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerX = rect.width / 2
        let outerY = rect.height / 2
        let innerX = outerX * innerRadiusRatio
        let innerY = outerY * innerRadiusRatio

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - outerY))
        path.addLine(to: CGPoint(x: center.x + innerX, y: center.y - innerY))
        path.addLine(to: CGPoint(x: center.x + outerX, y: center.y))
        path.addLine(to: CGPoint(x: center.x + innerX, y: center.y + innerY))
        path.addLine(to: CGPoint(x: center.x, y: center.y + outerY))
        path.addLine(to: CGPoint(x: center.x - innerX, y: center.y + innerY))
        path.addLine(to: CGPoint(x: center.x - outerX, y: center.y))
        path.addLine(to: CGPoint(x: center.x - innerX, y: center.y - innerY))
        path.closeSubpath()
        return path
    }
}
