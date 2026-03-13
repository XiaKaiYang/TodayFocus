import SwiftUI
import WidgetKit

private struct FocusSessionWidgetEntry: TimelineEntry {
    let date: Date
}

private struct FocusSessionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusSessionWidgetEntry {
        FocusSessionWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusSessionWidgetEntry) -> Void) {
        completion(FocusSessionWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusSessionWidgetEntry>) -> Void) {
        let entry = FocusSessionWidgetEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

private struct FocusSessionWidgetView: View {
    let entry: FocusSessionWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FocusSession")
                .font(.headline)
            Text(entry.date, style: .time)
                .font(.title2)
            Text("Current session widget placeholder")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

struct FocusSessionWidget: Widget {
    let kind = "FocusSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusSessionWidgetProvider()) { entry in
            FocusSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Session")
        .description("Shows the current focus session at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct FocusSessionWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusSessionWidget()
    }
}
