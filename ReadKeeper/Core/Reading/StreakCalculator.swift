import Foundation

struct StreakSummary: Equatable, Sendable {
    /// Days read in the current streak (rest days don't count, but don't break it).
    var current: Int
    var readToday: Bool
    /// True when this week's free rest day has already been used.
    var restDayUsedThisWeek: Bool

    static let empty = StreakSummary(current: 0, readToday: false, restDayUsedThisWeek: false)
}

/// Forgiving reading streaks:
/// - Today never breaks the streak (you still have time to read).
/// - One missed day per calendar week is a free rest day.
/// - A second missed day in the same week ends the streak.
enum StreakCalculator {
    static func summary(activityDays: Set<Date>, today: Date, calendar: Calendar = .current) -> StreakSummary {
        let days = Set(activityDays.map { calendar.startOfDay(for: $0) })
        let todayStart = calendar.startOfDay(for: today)
        let readToday = days.contains(todayStart)
        guard let earliest = days.min(), earliest <= todayStart else { return .empty }

        var streak = 0
        var restWeeks = Set<WeekKey>()
        var cursor = readToday ? todayStart : day(before: todayStart, calendar: calendar)

        while cursor >= earliest {
            if days.contains(cursor) {
                streak += 1
            } else {
                let week = WeekKey(date: cursor, calendar: calendar)
                if restWeeks.contains(week) { break }
                restWeeks.insert(week)
            }
            cursor = day(before: cursor, calendar: calendar)
        }

        let restUsedThisWeek = streak > 0 && restWeeks.contains(WeekKey(date: todayStart, calendar: calendar))
        return StreakSummary(current: streak, readToday: readToday, restDayUsedThisWeek: restUsedThisWeek)
    }

    private static func day(before date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(-86_400)
    }

    private struct WeekKey: Hashable {
        let year: Int
        let week: Int

        init(date: Date, calendar: Calendar) {
            let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            year = parts.yearForWeekOfYear ?? 0
            week = parts.weekOfYear ?? 0
        }
    }
}
