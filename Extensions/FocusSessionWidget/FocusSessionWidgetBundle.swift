import FocusSessionCore
import SwiftUI
import WidgetKit

private struct FocusSessionWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: GoalProgressWidgetSnapshot
}

private struct FocusSessionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusSessionWidgetEntry {
        FocusSessionWidgetEntry(
            date: .now,
            snapshot: .preview
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusSessionWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusSessionWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(1800)))
        completion(timeline)
    }

    private func loadEntry() -> FocusSessionWidgetEntry {
        let snapshot = (try? GoalProgressWidgetStore()).flatMap { try? $0.read() }
            ?? GoalProgressWidgetSnapshot(items: [], updatedAt: .now)
        return FocusSessionWidgetEntry(
            date: snapshot.updatedAt,
            snapshot: snapshot
        )
    }
}

private struct FocusSessionWidgetView: View {
    let entry: FocusSessionWidgetEntry

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

            if entry.snapshot.items.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(entry.snapshot.items) { item in
                        progressPill(for: item)
                    }
                }
                .padding(14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(FocusSessionDeepLink.planURL)
        .containerBackground(.clear, for: .widget)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No active goals")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.82))
            Text("Open Plan")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.56))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(18)
    }

    private func progressPill(for item: GoalProgressWidgetItem) -> some View {
        let palette = colors(for: item.tintToken)

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.track)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.fill)
                    .frame(
                        width: geometry.size.width * (CGFloat(item.progressPercent) / 100),
                        alignment: .leading
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.82))
                        .lineLimit(1)
                    Text(item.progressLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.76))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(height: 56)
    }

    private func colors(for token: GoalProgressWidgetTintToken) -> (track: Color, fill: Color) {
        switch token {
        case .lilac:
            return (Color(red: 0.92, green: 0.91, blue: 0.98), Color(red: 0.82, green: 0.80, blue: 0.94))
        case .sky:
            return (Color(red: 0.89, green: 0.94, blue: 0.98), Color(red: 0.74, green: 0.88, blue: 0.97))
        case .peach:
            return (Color(red: 0.98, green: 0.91, blue: 0.88), Color(red: 0.98, green: 0.78, blue: 0.72))
        case .sage:
            return (Color(red: 0.91, green: 0.95, blue: 0.89), Color(red: 0.79, green: 0.88, blue: 0.73))
        case .mint:
            return (Color(red: 0.91, green: 0.96, blue: 0.90), Color(red: 0.66, green: 0.88, blue: 0.59))
        case .amber:
            return (Color(red: 0.98, green: 0.94, blue: 0.85), Color(red: 0.98, green: 0.84, blue: 0.47))
        }
    }
}

private extension GoalProgressWidgetSnapshot {
    static var preview: GoalProgressWidgetSnapshot {
        GoalProgressWidgetSnapshot(
            items: [
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Reading Influence",
                    progressPercent: 40,
                    progressLabel: "40%",
                    tintToken: .lilac
                ),
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Weight Management",
                    progressPercent: 100,
                    progressLabel: "100%",
                    tintToken: .sky
                ),
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Weekly Exercise",
                    progressPercent: 25,
                    progressLabel: "25%",
                    tintToken: .peach
                ),
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Vocabulary Learning",
                    progressPercent: 44,
                    progressLabel: "44%",
                    tintToken: .sage
                ),
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Cycling",
                    progressPercent: 67,
                    progressLabel: "67%",
                    tintToken: .mint
                )
            ],
            updatedAt: .now
        )
    }
}

struct FocusSessionWidget: Widget {
    let kind = "FocusSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusSessionWidgetProvider()) { entry in
            FocusSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Goals Progress")
        .description("Shows active goal progress at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct FocusSessionWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusSessionWidget()
    }
}
