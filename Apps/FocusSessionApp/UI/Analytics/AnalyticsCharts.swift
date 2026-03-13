import SwiftUI
import FocusSessionCore

struct AnalyticsTrendPieChartView: View {
    let buckets: [AnalyticsTrendBucket]
    let selectedRangeTitle: String
    let emptyText: String

    @State private var hoveredSliceID: String?

    private var slices: [AnalyticsPieSliceDescriptor] {
        let activeBuckets = buckets.filter { $0.totalSeconds > 0 }

        return activeBuckets.enumerated().map { index, bucket in
            AnalyticsPieSliceDescriptor(
                id: bucket.id,
                title: bucket.title,
                value: bucket.totalSeconds,
                supportingText: bucket.supportingText,
                color: analyticsPiePalette[index % analyticsPiePalette.count]
            )
        }
    }

    private var totalSeconds: Int {
        slices.reduce(0) { $0 + $1.value }
    }

    private var activeBucketCount: Int {
        buckets.filter { $0.totalSeconds > 0 }.count
    }

    private var selectedSlice: AnalyticsPieSliceDescriptor? {
        slices.first { $0.id == hoveredSliceID }
    }

    var body: some View {
        AnalyticsPieChartCard(
            slices: slices,
            emptyText: emptyText,
            hoveredSliceID: $hoveredSliceID
        ) {
            if let selectedSlice {
                AnalyticsPieDetailPanel(
                    eyebrow: selectedSlice.title,
                    value: analyticsDurationText(selectedSlice.value),
                    emphasis: analyticsPercentageText(value: selectedSlice.value, total: totalSeconds),
                    supportingText: selectedSlice.supportingText,
                    tint: selectedSlice.color
                )
            } else {
                AnalyticsPieDetailPanel(
                    eyebrow: selectedRangeTitle,
                    value: analyticsDurationText(totalSeconds),
                    emphasis: "\(activeBucketCount) active buckets",
                    supportingText: "Hover a slice to inspect a specific bucket.",
                    tint: nil
                )
            }
        }
    }
}

struct TaskBreakdownPieChartView: View {
    let rows: [AnalyticsFocusRow]
    let emptyText: String

    @State private var hoveredSliceID: String?

    private var slices: [AnalyticsPieSliceDescriptor] {
        rows.enumerated().map { index, row in
            AnalyticsPieSliceDescriptor(
                id: row.id,
                title: row.title,
                value: row.totalSeconds,
                supportingText: "\(row.sessionCount) completed sessions",
                color: analyticsPiePalette[index % analyticsPiePalette.count]
            )
        }
    }

    private var totalSeconds: Int {
        slices.reduce(0) { $0 + $1.value }
    }

    private var selectedSlice: AnalyticsPieSliceDescriptor? {
        slices.first { $0.id == hoveredSliceID }
    }

    var body: some View {
        AnalyticsPieChartCard(
            slices: slices,
            emptyText: emptyText,
            hoveredSliceID: $hoveredSliceID
        ) {
            if let selectedSlice {
                AnalyticsPieDetailPanel(
                    eyebrow: selectedSlice.title,
                    value: analyticsDurationText(selectedSlice.value),
                    emphasis: analyticsPercentageText(value: selectedSlice.value, total: totalSeconds),
                    supportingText: selectedSlice.supportingText,
                    tint: selectedSlice.color
                )
            } else {
                AnalyticsPieDetailPanel(
                    eyebrow: "Top task total",
                    value: analyticsDurationText(totalSeconds),
                    emphasis: "\(slices.count) tracked tasks",
                    supportingText: "Hover a slice to inspect a task breakdown.",
                    tint: nil
                )
            }
        }
    }
}

private struct AnalyticsPieChartCard<DetailContent: View>: View {
    let slices: [AnalyticsPieSliceDescriptor]
    let emptyText: String
    @Binding var hoveredSliceID: String?
    @ViewBuilder let detailContent: () -> DetailContent

    var body: some View {
        if slices.isEmpty {
            Text(emptyText)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 260)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                AnalyticsPieGraphic(
                    slices: slices,
                    hoveredSliceID: $hoveredSliceID
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)

                detailContent()

                AnalyticsPieLegend(
                    slices: slices,
                    hoveredSliceID: $hoveredSliceID
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AnalyticsPieGraphic: View {
    let slices: [AnalyticsPieSliceDescriptor]
    @Binding var hoveredSliceID: String?

    private var layouts: [AnalyticsPieSliceLayout] {
        analyticsPieLayouts(for: slices)
    }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                ForEach(layouts) { layout in
                    let isHovered = hoveredSliceID == layout.id

                    AnalyticsPieSliceShape(
                        startAngle: layout.startAngle,
                        endAngle: layout.endAngle
                    )
                    .fill(layout.slice.color)
                    .overlay {
                        AnalyticsPieSliceShape(
                            startAngle: layout.startAngle,
                            endAngle: layout.endAngle
                        )
                        .stroke(
                            isHovered
                                ? Color.white.opacity(0.94)
                                : Color.white.opacity(0.48),
                            lineWidth: isHovered ? 4 : 1.2
                        )
                    }
                    .opacity(hoveredSliceID == nil || isHovered ? 1 : 0.74)
                    .contentShape(
                        AnalyticsPieSliceShape(
                            startAngle: layout.startAngle,
                            endAngle: layout.endAngle
                        )
                    )
                    .onHover { isHovering in
                        if isHovering {
                            hoveredSliceID = layout.id
                        } else if hoveredSliceID == layout.id {
                            hoveredSliceID = nil
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.16), value: hoveredSliceID)
        }
    }
}

private struct AnalyticsPieLegend: View {
    let slices: [AnalyticsPieSliceDescriptor]
    @Binding var hoveredSliceID: String?

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(slices) { slice in
                let isHovered = hoveredSliceID == slice.id

                HStack(spacing: 8) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 10, height: 10)

                    Text(slice.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppGlassRoundedSurface(cornerRadius: 14, tint: isHovered ? slice.color : nil))
                .onHover { isHovering in
                    if isHovering {
                        hoveredSliceID = slice.id
                    } else if hoveredSliceID == slice.id {
                        hoveredSliceID = nil
                    }
                }
            }
        }
    }
}

private struct AnalyticsPieDetailPanel: View {
    let eyebrow: String
    let value: String
    let emphasis: String
    let supportingText: String
    let tint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Text(emphasis)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }

            Text(supportingText)
                .font(.caption)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppGlassRoundedSurface(cornerRadius: 20, tint: tint))
    }
}

private struct AnalyticsPieSliceDescriptor: Identifiable {
    let id: String
    let title: String
    let value: Int
    let supportingText: String
    let color: Color
}

private struct AnalyticsPieSliceLayout: Identifiable {
    let slice: AnalyticsPieSliceDescriptor
    let startAngle: Angle
    let endAngle: Angle

    var id: String { slice.id }
}

private struct AnalyticsPieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

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

private let analyticsPiePalette: [Color] = [
    Color(red: 0.86, green: 0.38, blue: 0.34),
    Color(red: 0.93, green: 0.64, blue: 0.29),
    Color(red: 0.44, green: 0.70, blue: 0.48),
    Color(red: 0.22, green: 0.62, blue: 0.67),
    Color(red: 0.30, green: 0.48, blue: 0.78),
    Color(red: 0.61, green: 0.45, blue: 0.74),
    Color(red: 0.78, green: 0.46, blue: 0.58)
]

private func analyticsPieLayouts(for slices: [AnalyticsPieSliceDescriptor]) -> [AnalyticsPieSliceLayout] {
    let totalValue = max(slices.reduce(0) { $0 + $1.value }, 1)
    var currentDegrees = -90.0

    return slices.map { slice in
        let angleSpan = Double(slice.value) / Double(totalValue) * 360
        let layout = AnalyticsPieSliceLayout(
            slice: slice,
            startAngle: .degrees(currentDegrees),
            endAngle: .degrees(currentDegrees + angleSpan)
        )
        currentDegrees += angleSpan
        return layout
    }
}

private func analyticsDurationText(_ seconds: Int) -> String {
    let minutes = seconds / 60
    if minutes >= 60 {
        return "\(minutes / 60)h \(minutes % 60)m"
    }
    return "\(minutes)m"
}

private func analyticsPercentageText(value: Int, total: Int) -> String {
    guard total > 0 else { return "0%" }
    let percentage = Double(value) / Double(total)
    return percentage.formatted(.percent.precision(.fractionLength(0)))
}
