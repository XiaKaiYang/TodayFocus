import SwiftUI

private struct FocusClockSectorShape: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), FocusClockDialMath.maxDialProgress)
        guard clampedProgress > 0 else {
            return Path()
        }

        if clampedProgress >= (FocusClockDialMath.maxDialProgress - 0.0001) {
            return Path(ellipseIn: rect)
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees((clampedProgress * 360) - 90)

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

enum FocusClockDialMath {
    static let dialMinutes = 60
    static let minMinutes = 0
    static let maxMinutes = 60
    static let majorTickMinutes = 5
    static let maxDialProgress = 1 - 0.0001

    static func normalizedValue(for point: CGPoint, in size: CGSize) -> Double {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dx, -dy)
        let positiveAngle = angle < 0 ? angle + (2 * .pi) : angle
        return positiveAngle / (2 * .pi)
    }

    static func minutes(for normalizedValue: Double) -> Int {
        let clamped = min(max(normalizedValue, 0), maxDialProgress)
        let rawMinutes = clamped * Double(dialMinutes)
        let roundedMinutes = rawMinutes.rounded()
        return min(max(Int(roundedMinutes), minMinutes), maxMinutes)
    }

    static func normalizedValue(forMinutes minutes: Int) -> Double {
        let clampedMinutes = min(max(minutes, minMinutes), maxMinutes)
        if clampedMinutes == maxMinutes {
            return maxDialProgress
        }
        return Double(clampedMinutes) / Double(dialMinutes)
    }

    static func point(
        for normalizedValue: Double,
        in size: CGSize,
        radiusInset: CGFloat = 26
    ) -> CGPoint {
        let wrappedValue = normalizedValue.truncatingRemainder(dividingBy: 1)
        let angle = wrappedValue * (2 * .pi)
        let radius = (min(size.width, size.height) / 2) - radiusInset
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGPoint(
            x: center.x + CGFloat(sin(angle)) * radius,
            y: center.y - CGFloat(cos(angle)) * radius
        )
    }
}

struct FocusClockDialView: View {
    let progress: Double
    let minutes: Int
    let showsCenterReadout: Bool
    let usesSoftPlatter: Bool
    let hubDiameter: CGFloat
    let handShadowRadius: CGFloat
    let isInteractive: Bool
    let onChanged: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let normalizedProgress = min(max(progress, 0), FocusClockDialMath.maxDialProgress)
            let handAngle = Angle.degrees((normalizedProgress * 360) - 90)
            let isZeroState = minutes == 0
            let platterFill = isZeroState
                ? Color(red: 0.80, green: 0.81, blue: 0.84).opacity(0.14)
                : Color(red: 0.93, green: 0.85, blue: 0.76).opacity(0.28)
            let platterStroke = isZeroState
                ? Color.black.opacity(0.04)
                : Color(red: 0.78, green: 0.70, blue: 0.61).opacity(0.18)
            let innerPlateBase = isZeroState
                ? Color(red: 0.79, green: 0.80, blue: 0.82).opacity(0.38)
                : Color(red: 0.35, green: 0.21, blue: 0.21).opacity(0.92)
            let innerPlateSelected = isZeroState
                ? Color.clear
                : Color(red: 0.86, green: 0.48, blue: 0.47).opacity(0.90)
            let handColor = isZeroState
                ? Color.white.opacity(0.38)
                : Color(red: 1.0, green: 0.26, blue: 0.25)
            let hubStroke = isZeroState ? Color.white.opacity(0.18) : Color.white.opacity(0.28)
            let hubFillColors: [Color] = isZeroState
                ? [
                    Color.white.opacity(0.92),
                    Color(red: 0.88, green: 0.88, blue: 0.90)
                ]
                : [
                    Color(red: 0.98, green: 0.95, blue: 0.96),
                    Color(red: 0.88, green: 0.84, blue: 0.85)
                ]
            let hubShadowColor = isZeroState
                ? Color.white.opacity(0.10)
                : Color.black.opacity(0.14)

            ZStack {
                if usesSoftPlatter {
                    Circle()
                        .fill(platterFill)
                        .frame(width: size.width * 0.86, height: size.width * 0.86)
                        .overlay(
                            Circle()
                                .stroke(platterStroke, lineWidth: 1)
                        )
                }

                Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)

                Circle()
                    .fill(innerPlateBase)
                    .frame(width: size.width * 0.58, height: size.width * 0.58)
                    .overlay(
                        FocusClockSectorShape(progress: normalizedProgress)
                            .fill(innerPlateSelected)
                            .frame(width: size.width * 0.58, height: size.width * 0.58)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isZeroState ? Color.white.opacity(0.06) : Color.white.opacity(0.10),
                                lineWidth: 1
                            )
                    )

                dialTicks(in: size, isZeroState: isZeroState)

                Capsule(style: .continuous)
                    .fill(handColor)
                    .frame(width: size.width * 0.36, height: size.width * 0.045)
                    .offset(x: size.width * 0.18)
                    .rotationEffect(handAngle)
                    .shadow(
                        color: (isZeroState
                            ? Color.white.opacity(0.10)
                            : Color(red: 1.0, green: 0.24, blue: 0.25).opacity(0.35)),
                        radius: handShadowRadius
                    )

                if showsCenterReadout {
                    VStack(spacing: 7) {
                        Text("\(minutes)")
                            .font(.system(size: size.width * 0.11, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppSurfaceTheme.primaryText.opacity(isZeroState ? 0.52 : 0.92))

                        Text("minutes")
                            .font(.system(size: size.width * 0.045, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText.opacity(isZeroState ? 0.72 : 0.92))
                    }
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: hubFillColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: hubDiameter, height: hubDiameter)
                    .overlay(
                        Circle()
                            .stroke(hubStroke, lineWidth: 3)
                    )
                    .shadow(color: hubShadowColor, radius: 10, y: 4)
            }
            .contentShape(Circle())
            .animation(.easeOut(duration: 0.10), value: progress)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isInteractive else {
                            return
                        }

                        onChanged(
                            FocusClockDialMath.normalizedValue(
                                for: gesture.location,
                                in: size
                            )
                        )
                    }
            )
        }
    }

    private func dialTicks(in size: CGSize, isZeroState: Bool) -> some View {
        let majorRadius = (min(size.width, size.height) / 2) - 18
        let minorRadius = (min(size.width, size.height) / 2) - 18

        return ZStack {
            ForEach(0..<FocusClockDialMath.dialMinutes, id: \.self) { index in
                let isMajor = index.isMultiple(of: FocusClockDialMath.majorTickMinutes)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        isZeroState
                            ? Color.black.opacity(isMajor ? 0.24 : 0.16)
                            : Color.black.opacity(isMajor ? 0.58 : 0.34)
                    )
                    .frame(width: isMajor ? 4 : 3, height: isMajor ? 28 : 14)
                    .offset(y: -(isMajor ? majorRadius : minorRadius))
                    .rotationEffect(.degrees(Double(index) * 6))
            }
        }
    }
}
