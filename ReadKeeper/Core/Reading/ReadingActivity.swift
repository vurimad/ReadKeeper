import Foundation
import SwiftData

struct WeekSummary: Equatable, Sendable {
    var pages: Int
    var listeningMinutes: Int
    var daysRead: Int
}

/// Gathers reading activity across the library for streaks and weekly stats.
enum ReadingActivity {
    /// Days with forward progress, plus days a book was finished.
    static func activityDays(books: [Book]) -> Set<Date> {
        var days = Set<Date>()
        for book in books {
            for log in book.readingLogs ?? [] where log.amount > 0 {
                days.insert(log.date)
            }
            if let finished = book.dateFinished {
                days.insert(finished)
            }
        }
        return days
    }

    /// "Read today", "Last read yesterday", "Last read 3 days ago", or nil if never logged.
    static func lastReadText(lastRead: Date?, now: Date, calendar: Calendar = .current) -> String? {
        guard let lastRead else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastRead),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        switch days {
        case ..<1: return "Read today"
        case 1: return "Last read yesterday"
        default: return "Last read \(days) days ago"
        }
    }

    static func weekSummary(books: [Book], now: Date, calendar: Calendar = .current) -> WeekSummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return WeekSummary(pages: 0, listeningMinutes: 0, daysRead: 0)
        }
        var pages = 0.0
        var minutes = 0.0
        var days = Set<Date>()
        for book in books {
            for log in book.readingLogs ?? [] where log.amount > 0 && week.contains(log.date) {
                pages += ProgressMath.pagesRead(amount: log.amount, unit: log.unit, pageCount: book.pageCount)
                if log.unit == .minutes {
                    minutes += ProgressMath.listeningMinutes(bookMinutes: log.amount, speed: log.playbackSpeed)
                }
                days.insert(calendar.startOfDay(for: log.date))
            }
        }
        return WeekSummary(pages: Int(pages.rounded()), listeningMinutes: Int(minutes.rounded()), daysRead: days.count)
    }
}

extension Book {
    /// Records reading progress up to `newValue` on `date` (today or a past day).
    ///
    /// - Starts the book if it wasn't being read yet, and moves the start date back when backfilling.
    /// - Switching the unit (e.g. pages to percent) starts counting from zero in the new unit.
    /// - `finished` marks the book as read on `date`.
    @discardableResult
    func logProgress(
        to newValue: Double,
        unit: ProgressUnit,
        on date: Date,
        finished: Bool = false,
        context: ModelContext
    ) -> ReadingLog? {
        if unit != progressUnit {
            progressUnit = unit
            progressValue = 0
        }
        let start = progressValue
        var end = ProgressMath.clamp(newValue, unit: unit, pageCount: pageCount, totalMinutes: totalMinutes)
        if finished, let total = ProgressMath.total(unit: unit, pageCount: pageCount, totalMinutes: totalMinutes) {
            end = total
        }

        var log: ReadingLog?
        if end != start {
            let entry = ReadingLog(date: date, startValue: start, endValue: end, unit: unit, playbackSpeed: playbackSpeed)
            context.insert(entry)
            entry.book = self
            log = entry
        }
        progressValue = end

        if status == .wantToRead || status == .dnf {
            setStatus(.reading, now: date)
        }
        if let started = dateStarted, date < started {
            dateStarted = date
        }
        if finished {
            setStatus(.read, now: date)
        }
        return log
    }
}
