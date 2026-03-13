import SwiftUI

private struct FocusEntryStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let depth: CGFloat
    let brightness: Double
}

private enum FocusEntryStarfieldModel {
    static let stars: [FocusEntryStar] = (0..<96).map { index in
        let base = Double(index) * 12.9898
        let randomX = sin(base) * 43_758.5453
        let randomY = cos(base * 1.618) * 24_634.6345
        let randomDepth = sin(base * 0.713) * 9_873.3456

        let normalizedX = CGFloat((randomX - floor(randomX)) * 2 - 1)
        let normalizedY = CGFloat((randomY - floor(randomY)) * 2 - 1)
        let depth = CGFloat(max(0.15, randomDepth - floor(randomDepth)))
        let brightness = 0.45 + Double(depth) * 0.5

        return FocusEntryStar(
            id: index,
            x: normalizedX,
            y: normalizedY,
            depth: depth,
            brightness: brightness
        )
    }
}

struct FocusAmbientStarfieldView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for star in FocusEntryStarfieldModel.stars {
                    let driftX = sin(time * 0.16 + Double(star.id)) * Double(star.depth) * 8
                    let driftY = cos(time * 0.12 + Double(star.id) * 0.7) * Double(star.depth) * 5
                    let twinkle = 0.35 + (0.65 * (0.5 + (0.5 * sin(time * (0.8 + Double(star.depth)) + Double(star.id)))))
                    let point = CGPoint(
                        x: (size.width * (0.5 + (star.x * 0.46))) + driftX,
                        y: (size.height * (0.5 + (star.y * 0.46))) + driftY
                    )
                    let starSize = 1.0 + (3.2 * star.depth)
                    let rect = CGRect(
                        x: point.x - (starSize / 2),
                        y: point.y - (starSize / 2),
                        width: starSize,
                        height: starSize
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(
                            Color(red: 0.53, green: 0.46, blue: 0.42)
                                .opacity(twinkle * star.brightness * 0.20)
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
