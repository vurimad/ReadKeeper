import Foundation
import SwiftData
import Testing
@testable import ReadKeeper

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}

private func finishedBook(_ title: String, pages: Int?, on date: Date, rating: Double? = nil, tropes: [String] = [], format: BookFormat = .paperback) -> Book {
    let book = Book(title: title, author: "Author", pageCount: pages, format: format)
    book.setStatus(.read, now: date)
    book.rating = rating
    book.tropes = tropes
    return book
}

struct YearStatsTests {
    @Test func countsOnlyBooksFinishedThatYear() {
        let books = [
            finishedBook("A", pages: 300, on: day(2026, 1, 10), rating: 5, tropes: ["Slow burn", "Found family"]),
            finishedBook("B", pages: 500, on: day(2026, 1, 20), rating: 4, tropes: ["Slow burn"], format: .audiobook),
            finishedBook("C", pages: nil, on: day(2026, 3, 5), rating: 3, tropes: ["Heist"]),
            finishedBook("Last year", pages: 900, on: day(2025, 12, 31), rating: 1),
            Book(title: "Still reading", author: "X", pageCount: 200),
        ]
        let stats = YearStats.compute(books: books, year: 2026, calendar: calendar)
        #expect(stats.booksFinished == 3)
        #expect(stats.pagesFinished == 800)
        #expect(stats.booksPerMonth[0] == 2)
        #expect(stats.booksPerMonth[2] == 1)
        #expect(stats.booksPerMonth.reduce(0, +) == 3)
        #expect(stats.averageRating == 4)
        #expect(stats.fiveStarCount == 1)
        #expect(stats.formatCounts[.paperback] == 2)
        #expect(stats.formatCounts[.audiobook] == 1)
        #expect(stats.topTropes.first == "Slow burn")
        #expect(stats.topTropes.count == 3)
        #expect(stats.longestBookTitle == "B")
        #expect(stats.longestBookPages == 500)
        #expect(stats.busiestMonth == 0)
    }

    @Test func emptyYear() {
        let stats = YearStats.compute(books: [], year: 2026, calendar: calendar)
        #expect(stats.booksFinished == 0)
        #expect(stats.averageRating == nil)
        #expect(stats.busiestMonth == nil)
        #expect(stats.booksPerMonth == Array(repeating: 0, count: 12))
    }

    @Test func averageIsRoundedToOneDecimal() {
        let books = [
            finishedBook("A", pages: 1, on: day(2026, 2, 1), rating: 4.5),
            finishedBook("B", pages: 1, on: day(2026, 2, 2), rating: 4),
            finishedBook("C", pages: 1, on: day(2026, 2, 3), rating: 4),
        ]
        #expect(YearStats.compute(books: books, year: 2026, calendar: calendar).averageRating == 4.2)
    }
}

struct WidgetSnapshotTests {
    @Test func readTodayExpiresAtMidnight() {
        var snapshot = WidgetSnapshot.placeholder
        snapshot.generatedAt = day(2026, 11, 19)
        snapshot.readToday = true
        #expect(snapshot.hasReadToday(at: day(2026, 11, 19).addingTimeInterval(3_600), calendar: calendar))
        #expect(!snapshot.hasReadToday(at: day(2026, 11, 20), calendar: calendar))
    }

    @Test func goalFraction() {
        var snapshot = WidgetSnapshot.placeholder
        snapshot.goal = 20
        snapshot.finishedThisYear = 5
        #expect(snapshot.goalFraction == 0.25)
        snapshot.finishedThisYear = 30
        #expect(snapshot.goalFraction == 1)
        snapshot.goal = 0
        #expect(snapshot.goalFraction == nil)
    }

    @Test func survivesEncoding() throws {
        let data = try JSONEncoder().encode(WidgetSnapshot.placeholder)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        #expect(decoded == WidgetSnapshot.placeholder)
    }

    @MainActor
    @Test func builtFromTheLibrary() throws {
        let container = try ModelContainer(
            for: Book.self, ReadingLog.self, Quote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let now = day(2026, 11, 19)

        let reading = Book(title: "Emma", author: "Jane Austen", pageCount: 400)
        context.insert(reading)
        reading.logProgress(to: 100, unit: .pages, on: now, context: context)
        let done = Book(title: "Dracula", author: "Bram Stoker")
        context.insert(done)
        done.setStatus(.read, now: day(2026, 3, 1))
        let wishlist = Book(title: "Persuasion", author: "Jane Austen")
        context.insert(wishlist)

        let snapshot = WidgetRefresher.makeSnapshot(books: [reading, done, wishlist], goal: 12, now: now, calendar: calendar)
        #expect(snapshot.reading.map(\.title) == ["Emma"])
        #expect(snapshot.reading.first?.fraction == 0.25)
        #expect(snapshot.reading.first?.progressText == "p. 100 of 400")
        #expect(snapshot.readToday)
        #expect(snapshot.streakDays == 1)
        #expect(snapshot.goal == 12)
        #expect(snapshot.finishedThisYear == 1)
        #expect(snapshot.year == 2026)
    }
}
