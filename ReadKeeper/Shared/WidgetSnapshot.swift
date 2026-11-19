import Foundation

/// A small summary the app writes for the widgets: what you're reading, your streak and your goal.
/// Shared with the widget extension through an App Group container.
struct WidgetSnapshot: Codable, Sendable, Equatable {
    struct ReadingItem: Codable, Sendable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var author: String
        /// 0...1, nil when the length is unknown.
        var fraction: Double?
        var progressText: String
        /// Small JPEG of the cover, if the app has one saved.
        var coverThumbnail: Data?
    }

    var generatedAt: Date
    var reading: [ReadingItem]
    var streakDays: Int
    var readToday: Bool
    var goal: Int
    var finishedThisYear: Int
    var year: Int

    /// "Read today" only counts on the day the snapshot was made.
    func hasReadToday(at date: Date, calendar: Calendar = .current) -> Bool {
        readToday && calendar.isDate(generatedAt, inSameDayAs: date)
    }

    var goalFraction: Double? {
        goal > 0 ? min(Double(finishedThisYear) / Double(goal), 1) : nil
    }

    static let empty = WidgetSnapshot(
        generatedAt: .now, reading: [], streakDays: 0, readToday: false,
        goal: 0, finishedThisYear: 0, year: Calendar.current.component(.year, from: .now)
    )

    /// Shown in the widget gallery before the app has written anything.
    static let placeholder = WidgetSnapshot(
        generatedAt: .now,
        reading: [
            ReadingItem(id: UUID(), title: "Pride and Prejudice", author: "Jane Austen", fraction: 0.57, progressText: "p. 245 of 432", coverThumbnail: nil),
            ReadingItem(id: UUID(), title: "Moby-Dick", author: "Herman Melville", fraction: 0.28, progressText: "6h 50m of 24h 20m", coverThumbnail: nil),
        ],
        streakDays: 6,
        readToday: true,
        goal: 24,
        finishedThisYear: 16,
        year: Calendar.current.component(.year, from: .now)
    )
}

/// Reads and writes the snapshot in the App Group container.
enum WidgetSnapshotStore {
    static let appGroupID = "group.com.vurimad.readkeeper"

    /// Nil until the App Group capability is set up (needs the Apple Developer account).
    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "widget-snapshot.json")
    }

    @discardableResult
    static func save(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return false }
        return (try? data.write(to: url, options: .atomic)) != nil
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
