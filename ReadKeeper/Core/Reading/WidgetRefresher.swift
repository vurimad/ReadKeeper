import Foundation
import SwiftData
import WidgetKit

/// Builds the widget snapshot from the library and asks WidgetKit to redraw.
@MainActor
enum WidgetRefresher {
    static func makeSnapshot(books: [Book], goal: Int, now: Date = .now, calendar: Calendar = .current) -> WidgetSnapshot {
        let reading = ShelfOrdering.sorted(books)
            .filter { $0.status == .reading }
            .prefix(3)
            .map { book in
                WidgetSnapshot.ReadingItem(
                    id: book.id,
                    title: book.title,
                    author: book.displayAuthor,
                    fraction: book.progressFraction,
                    progressText: book.progressText,
                    coverThumbnail: book.coverImageData.flatMap {
                        ImageDownscaler.jpegData(from: $0, maxDimension: 180, quality: 0.75)
                    }
                )
            }
        let streak = StreakCalculator.summary(
            activityDays: ReadingActivity.activityDays(books: books),
            today: now,
            calendar: calendar
        )
        let year = calendar.component(.year, from: now)
        return WidgetSnapshot(
            generatedAt: now,
            reading: Array(reading),
            streakDays: streak.current,
            readToday: streak.readToday,
            goal: goal,
            finishedThisYear: ReadingGoal.booksFinished(
                in: year,
                finishDates: books.filter { $0.status == .read }.compactMap(\.dateFinished),
                calendar: calendar
            ),
            year: year
        )
    }

    /// Call after reading changes and when the app goes to the background.
    static func refresh(context: ModelContext) {
        let books = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let goal = UserDefaults.standard.integer(forKey: ReadingGoal.storageKey)
        if WidgetSnapshotStore.save(makeSnapshot(books: books, goal: goal)) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
