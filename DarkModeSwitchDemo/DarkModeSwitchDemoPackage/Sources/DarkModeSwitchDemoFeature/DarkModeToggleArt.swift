struct ArtCircle: Equatable, Sendable {
    let x: Double
    let y: Double
    let radius: Double
}

struct CloudGroup: Equatable, Sendable {
    let circles: [ArtCircle]
    let opacity: Double
    let duration: Double
}

struct ArtStar: Equatable, Sendable {
    let group: Int
    let x: Double
    let y: Double
    let radius: Double
    let blurRadius: Double

    init(group: Int, x: Double, y: Double, radius: Double, blurRadius: Double = 0) {
        self.group = group
        self.x = x
        self.y = y
        self.radius = radius
        self.blurRadius = blurRadius
    }
}

enum DarkModeToggleArt {
    static let cloudGroups: [CloudGroup] = [
        CloudGroup(
            circles: [
                ArtCircle(x: 94.2504, y: 60.8421, radius: 13.65),
                ArtCircle(x: 113.184, y: 51.7523, radius: 13.65),
                ArtCircle(x: 114.229, y: 67.3172, radius: 13.65),
                ArtCircle(x: 130.307, y: 54.5105, radius: 13.65),
                ArtCircle(x: 137.664, y: 67.0455, radius: 13.65),
                ArtCircle(x: 151.322, y: 57.0073, radius: 13.65),
            ],
            opacity: 0.95,
            duration: 3.5
        ),
        CloudGroup(
            circles: [
                ArtCircle(x: 26.1573, y: 73.098, radius: 13.65),
                ArtCircle(x: 45.0905, y: 64.0083, radius: 13.65),
                ArtCircle(x: 46.1363, y: 79.5732, radius: 13.65),
                ArtCircle(x: 62.2139, y: 66.7665, radius: 13.65),
                ArtCircle(x: 69.5708, y: 79.3015, radius: 13.65),
                ArtCircle(x: 83.2286, y: 69.2632, radius: 13.65),
            ],
            opacity: 0.95,
            duration: 4.5
        ),
        CloudGroup(
            circles: [
                ArtCircle(x: 106.091, y: 43.1957, radius: 13.65),
                ArtCircle(x: 125.024, y: 34.106, radius: 13.65),
                ArtCircle(x: 126.07, y: 49.6709, radius: 13.65),
                ArtCircle(x: 142.148, y: 36.8642, radius: 13.65),
                ArtCircle(x: 149.505, y: 49.3992, radius: 13.65),
                ArtCircle(x: 163.162, y: 39.3609, radius: 13.65),
            ],
            opacity: 0.6,
            duration: 2.5
        ),
        CloudGroup(
            circles: [
                ArtCircle(x: 48.4171, y: 64.9256, radius: 13.65),
                ArtCircle(x: 67.2297, y: 55.5888, radius: 13.65),
                ArtCircle(x: 68.4791, y: 71.1387, radius: 13.65),
                ArtCircle(x: 84.3878, y: 58.1227, radius: 13.65),
                ArtCircle(x: 91.9081, y: 70.5603, radius: 13.65),
                ArtCircle(x: 105.433, y: 60.3442, radius: 13.65),
            ],
            opacity: 0.6,
            duration: 5.5
        ),
    ]

    static let stars: [ArtStar] = [
        ArtStar(group: 1, x: 16.95, y: 23.45, radius: 1.95),
        ArtStar(group: 2, x: 40.35, y: 33.85, radius: 1.95),
        ArtStar(group: 3, x: 22.15, y: 57.25, radius: 1.95),
        ArtStar(group: 4, x: 28.65, y: 36.45, radius: 0.65),
        ArtStar(group: 1, x: 18.25, y: 45.55, radius: 0.65),
        ArtStar(group: 2, x: 32.875, y: 58.875, radius: 0.975),
        ArtStar(group: 0, x: 15.975, y: 32.875, radius: 0.975, blurRadius: 0.13),
        ArtStar(group: 3, x: 10.45, y: 52.05, radius: 0.65),
        ArtStar(group: 4, x: 42.95, y: 49.45, radius: 0.65),
        ArtStar(group: 1, x: 31.25, y: 15.65, radius: 0.65),
        ArtStar(group: 2, x: 5.25, y: 36.45, radius: 0.65),
        ArtStar(group: 1, x: 50.75, y: 10.45, radius: 1.95),
        ArtStar(group: 3, x: 80.65, y: 23.45, radius: 1.95),
        ArtStar(group: 4, x: 62.45, y: 53.35, radius: 1.95),
        ArtStar(group: 2, x: 68.95, y: 26.05, radius: 0.65),
        ArtStar(group: 3, x: 63.75, y: 40.35, radius: 0.65),
        ArtStar(group: 1, x: 70.575, y: 34.175, radius: 0.975),
        ArtStar(group: 0, x: 56.275, y: 22.475, radius: 0.975, blurRadius: 0.13),
        ArtStar(group: 1, x: 50.75, y: 40.35, radius: 0.65, blurRadius: 0.13),
        ArtStar(group: 1, x: 83.25, y: 39.05, radius: 0.65),
        ArtStar(group: 2, x: 76.75, y: 13.05, radius: 0.65),
        ArtStar(group: 3, x: 45.55, y: 26.05, radius: 0.65),
    ]

    static let starDurations: [Int: Double] = [
        1: 3,
        2: 2,
        3: 1,
        4: 5,
    ]
}
