import Foundation
import SwiftData
import Testing
@testable import ReadKeeper

/// Fixed calendar so tests don't depend on the machine's locale or time zone.
/// Weeks start on Monday.
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
}()

/// Thursday, 19 November 2026, noon UTC.
private let thursday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 12))!

private func daysAgo(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: -days, to: thursday)!
}

struct StreakCalculatorTests {
    @Test func noActivityMeansNoStreak() {
        #expect(StreakCalculator.summary(activityDays: [], today: thursday, calendar: calendar) == .empty)
    }

    @Test func consecutiveDaysIncludingToday() {
        let days: Set<Date> = [daysAgo(0), daysAgo(1), daysAgo(2)]
        let summary = StreakCalculator.summary(activityDays: days, today: thursday, calendar: calendar)
        #expect(summary.current == 3)
        #expect(summary.readToday)
        #expect(!summary.restDayUsedThisWeek)
    }

    @Test func notReadingYetTodayDoesNotBreakTheStreak() {
        let days: Set<Date> = [daysAgo(1), daysAgo(2)]
        let summary = StreakCalculator.summary(activityDays: days, today: thursday, calendar: calendar)
        #expect(summary.current == 2)
        #expect(!summary.readToday)
    }

    @Test func oneMissedDayPerWeekIsARestDay() {
        // Thu, Wed, (Tue missed), Mon all in the same week.
        let days: Set<Date> = [daysAgo(0), daysAgo(1), daysAgo(3)]
        let summary = StreakCalculator.summary(activityDays: days, today: thursday, calendar: calendar)
        #expect(summary.current == 3)
        #expect(summary.restDayUsedThisWeek)
    }

    @Test func twoMissedDaysInOneWeekEndTheStreak() {
        // Thu read, Wed and Tue missed (same week): the streak is just today.
        let days: Set<Date> = [daysAgo(0), daysAgo(3), daysAgo(4)]
        let summary = StreakCalculator.summary(activityDays: days, today: thursday, calendar: calendar)
        #expect(summary.current == 1)
    }

    @Test func restDaysInDifferentWeeksAreBothAllowed() {
        // This week: Tue missed. Last week: Sat missed.
        let read = [0, 1, 3, 4, 5, 7, 8]
        let summary = StreakCalculator.summary(activityDays: Set(read.map(daysAgo)), today: thursday, calendar: calendar)
        #expect(summary.current == read.count)
    }

    @Test func multipleEntriesOnTheSameDayCountOnce() {
        let morning = calendar.date(byAdding: .hour, value: -4, to: thursday)!
        let summary = StreakCalculator.summary(activityDays: [thursday, morning], today: thursday, calendar: calendar)
        #expect(summary.current == 1)
    }
}

struct ProgressMathTests {
    @Test func fractions() {
        #expect(ProgressMath.fraction(value: 108, unit: .pages, pageCount: 432, totalMinutes: nil) == 0.25)
        #expect(ProgressMath.fraction(value: 45, unit: .percent, pageCount: nil, totalMinutes: nil) == 0.45)
        #expect(ProgressMath.fraction(value: 90, unit: .minutes, pageCount: nil, totalMinutes: 360) == 0.25)
        #expect(ProgressMath.fraction(value: 50, unit: .pages, pageCount: nil, totalMinutes: nil) == nil)
        #expect(ProgressMath.fraction(value: 999, unit: .pages, pageCount: 100, totalMinutes: nil) == 1)
    }

    @Test func clampsToTheBook() {
        #expect(ProgressMath.clamp(500, unit: .pages, pageCount: 432, totalMinutes: nil) == 432)
        #expect(ProgressMath.clamp(-5, unit: .percent, pageCount: nil, totalMinutes: nil) == 0)
        #expect(ProgressMath.clamp(500, unit: .pages, pageCount: nil, totalMinutes: nil) == 500)
    }

    @Test func audiobookSpeedChangesListeningTime() {
        #expect(ProgressMath.listeningMinutes(bookMinutes: 60, speed: 1.5) == 40)
        #expect(ProgressMath.listeningMinutes(bookMinutes: 60, speed: 1) == 60)
    }

    @Test func percentConvertsToPagesWhenPageCountKnown() {
        #expect(ProgressMath.pagesRead(amount: 10, unit: .percent, pageCount: 400) == 40)
        #expect(ProgressMath.pagesRead(amount: 10, unit: .percent, pageCount: nil) == 0)
        #expect(ProgressMath.pagesRead(amount: -10, unit: .pages, pageCount: 400) == 0)
    }

    @Test func formatting() {
        #expect(ProgressMath.positionText(value: 120, unit: .pages, pageCount: 432, totalMinutes: nil) == "p. 120 of 432")
        #expect(ProgressMath.positionText(value: 45.4, unit: .percent, pageCount: nil, totalMinutes: nil) == "45%")
        #expect(ProgressMath.positionText(value: 270, unit: .minutes, pageCount: nil, totalMinutes: 550) == "4h 30m of 9h 10m")
        #expect(ProgressMath.deltaText(24, unit: .pages) == "+24 pages")
        #expect(ProgressMath.deltaText(1, unit: .pages) == "+1 page")
        #expect(ProgressMath.deltaText(45, unit: .minutes) == "+45m")
        #expect(ProgressMath.durationText(minutes: 120) == "2h")
        #expect(ProgressMath.speedText(1.5) == "1.5×")
        #expect(ProgressMath.speedText(2) == "2×")
    }
}

struct ReadingGoalTests {
    @Test func countsOnlyThisYearsFinishes() {
        let dates = [daysAgo(1), daysAgo(30), calendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!]
        #expect(ReadingGoal.booksFinished(in: 2026, finishDates: dates, calendar: calendar) == 2)
    }

    @Test func paceMessages() {
        // 19 Nov is about 88% through the year: a 24-book goal expects ~21 by now.
        #expect(ReadingGoal.paceText(finished: 24, goal: 24, date: thursday, calendar: calendar) == "Goal reached!")
        #expect(ReadingGoal.paceText(finished: 21, goal: 24, date: thursday, calendar: calendar) == "On track")
        #expect(ReadingGoal.paceText(finished: 16, goal: 24, date: thursday, calendar: calendar) == "5 books behind schedule")
        #expect(ReadingGoal.paceText(finished: 23, goal: 24, date: thursday, calendar: calendar) == "2 books ahead of schedule")
        #expect(ReadingGoal.paceText(finished: 3, goal: 0, date: thursday, calendar: calendar).isEmpty)
    }
}

struct RatingAndTagTests {
    @Test func starTouchMapsToHalfSteps() {
        // Stars are 30pt wide with 6pt gaps (36pt per star).
        #expect(RatingMath.value(atX: 1, starWidth: 30, spacing: 6) == 0.5)
        #expect(RatingMath.value(atX: 30, starWidth: 30, spacing: 6) == 1)
        #expect(RatingMath.value(atX: 90, starWidth: 30, spacing: 6) == 2.5)
        #expect(RatingMath.value(atX: 500, starWidth: 30, spacing: 6) == 5)
        #expect(RatingMath.value(atX: -20, starWidth: 30, spacing: 6) == 0.5)
    }

    @Test func starSymbols() {
        #expect(RatingMath.symbol(forStar: 3, rating: 3.5) == "star.fill")
        #expect(RatingMath.symbol(forStar: 4, rating: 3.5) == "star.leadinghalf.filled")
        #expect(RatingMath.symbol(forStar: 5, rating: 3.5) == "star")
        #expect(RatingMath.symbol(forStar: 1, rating: nil) == "star")
    }

    @Test func tagsAreTrimmedAndDeduplicated() {
        var tags = TagList.adding("  Slow burn ", to: [])
        tags = TagList.adding("slow BURN", to: tags)
        tags = TagList.adding("Found family", to: tags)
        tags = TagList.adding("   ", to: tags)
        #expect(tags == ["Slow burn", "Found family"])
        #expect(TagList.removing("SLOW BURN", from: tags) == ["Found family"])
    }
}

struct LoggingTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Book.self, ReadingLog.self, Quote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func loggingStartsTheBookAndRecordsTheChange() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        context.insert(book)

        let log = book.logProgress(to: 50, unit: .pages, on: daysAgo(1), context: context)
        #expect(book.status == .reading)
        #expect(book.progressValue == 50)
        #expect(book.dateStarted == daysAgo(1))
        #expect(log?.amount == 50)
        #expect(book.readingLogs?.count == 1)
    }

    @Test func backfillingMovesTheStartDateBack() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        context.insert(book)
        book.logProgress(to: 80, unit: .pages, on: daysAgo(0), context: context)
        book.logProgress(to: 120, unit: .pages, on: daysAgo(5), context: context)
        #expect(book.dateStarted == daysAgo(5))
        #expect(book.readingLogs?.count == 2)
    }

    @Test func finishingSetsProgressToTheEndAndMarksRead() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        context.insert(book)
        book.logProgress(to: 400, unit: .pages, on: daysAgo(0), finished: true, context: context)
        #expect(book.status == .read)
        #expect(book.progressValue == 474)
        #expect(book.dateFinished == daysAgo(0))
    }

    @Test func pagesBeyondTheEndAreClamped() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        context.insert(book)
        book.logProgress(to: 9_999, unit: .pages, on: daysAgo(0), context: context)
        #expect(book.progressValue == 474)
    }

    @Test func switchingUnitStartsFromZeroInTheNewUnit() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        context.insert(book)
        book.logProgress(to: 100, unit: .pages, on: daysAgo(1), context: context)
        let log = book.logProgress(to: 30, unit: .percent, on: daysAgo(0), context: context)
        #expect(book.progressUnit == .percent)
        #expect(log?.startValue == 0)
        #expect(log?.endValue == 30)
    }

    @Test func audiobooksDefaultToTimeAndEbooksToPercent() {
        #expect(Book(title: "A", author: "B", format: .audiobook).progressUnit == .minutes)
        #expect(Book(title: "A", author: "B", format: .ebook).progressUnit == .percent)
        #expect(Book(title: "A", author: "B", format: .hardcover).progressUnit == .pages)
    }

    @Test func activityAndWeekSummaryFromLogs() throws {
        let context = try makeContext()
        let paper = Book(title: "Emma", author: "Jane Austen", pageCount: 400)
        let audio = Book(title: "Dracula", author: "Bram Stoker", format: .audiobook)
        audio.playbackSpeed = 1.5
        context.insert(paper)
        context.insert(audio)
        paper.logProgress(to: 40, unit: .pages, on: daysAgo(0), context: context)
        paper.logProgress(to: 70, unit: .pages, on: daysAgo(1), context: context)
        audio.logProgress(to: 90, unit: .minutes, on: daysAgo(1), context: context)

        let days = ReadingActivity.activityDays(books: [paper, audio])
        #expect(Set(days.map { calendar.startOfDay(for: $0) }).count == 2)

        let week = ReadingActivity.weekSummary(books: [paper, audio], now: thursday, calendar: calendar)
        #expect(week.pages == 70)
        #expect(week.listeningMinutes == 60) // 90 book-minutes at 1.5x
        #expect(week.daysRead == 2)
    }

    @Test func quotesAttachToTheBook() throws {
        let context = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen")
        context.insert(book)
        let quote = Quote(text: "Silly things do cease to be silly if they are done by sensible people.", page: 210)
        context.insert(quote)
        quote.book = book
        #expect(book.quotes?.count == 1)
        #expect(book.sortedQuotes.first?.page == 210)
    }
}
