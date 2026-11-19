import Foundation
import Testing
@testable import ReadKeeper

struct LastReadTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 9))! }

    private func daysAgo(_ days: Int, hour: Int = 22) -> Date {
        let day = calendar.date(byAdding: .day, value: -days, to: now)!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }

    @Test func describesHowLongAgo() {
        #expect(ReadingActivity.lastReadText(lastRead: nil, now: now, calendar: calendar) == nil)
        #expect(ReadingActivity.lastReadText(lastRead: daysAgo(0, hour: 7), now: now, calendar: calendar) == "Read today")
        // Late last night is still "yesterday", not "today".
        #expect(ReadingActivity.lastReadText(lastRead: daysAgo(1), now: now, calendar: calendar) == "Last read yesterday")
        #expect(ReadingActivity.lastReadText(lastRead: daysAgo(4), now: now, calendar: calendar) == "Last read 4 days ago")
    }
}
