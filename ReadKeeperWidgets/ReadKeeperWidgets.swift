import SwiftUI
import WidgetKit

@main
struct ReadKeeperWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentlyReadingWidget()
        StreakGoalWidget()
    }
}

struct SnapshotEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Shows the latest snapshot written by the app, and refreshes at midnight so "read today" resets.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (WidgetSnapshotStore.load() ?? .placeholder)
        completion(SnapshotEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date.now
        let snapshot = WidgetSnapshotStore.load() ?? .empty
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3_600)
        let entries = [
            SnapshotEntry(date: now, snapshot: snapshot),
            SnapshotEntry(date: midnight, snapshot: snapshot),
        ]
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(60))))
    }
}

struct CurrentlyReadingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CurrentlyReading", provider: SnapshotProvider()) { entry in
            CurrentlyReadingEntryView(entry: entry)
        }
        .configurationDisplayName("Currently Reading")
        .description("Your current book and how far you are.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

private struct CurrentlyReadingEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        CurrentlyReadingWidgetContent(family: family, snapshot: entry.snapshot, date: entry.date)
            .containerBackground(for: .widget) {
                WidgetBackground(family: family)
            }
    }
}

struct StreakGoalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakGoal", provider: SnapshotProvider()) { entry in
            StreakGoalEntryView(entry: entry)
        }
        .configurationDisplayName("Streak & Goal")
        .description("Your reading streak and yearly goal.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct StreakGoalEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        StreakGoalWidgetContent(family: family, snapshot: entry.snapshot, date: entry.date)
            .containerBackground(for: .widget) {
                WidgetBackground(family: family)
            }
    }
}

/// Warm card background on the Home Screen; the system's own background on the Lock Screen.
private struct WidgetBackground: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            AccessoryWidgetBackground()
        default:
            LinearGradient(colors: [Theme.card, Theme.cardGlow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
