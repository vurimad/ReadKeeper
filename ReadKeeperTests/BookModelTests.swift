import Foundation
import Testing
@testable import ReadKeeper

struct BookStatusTests {
    let monday = Date(timeIntervalSince1970: 1_700_000_000)
    var tuesday: Date { monday.addingTimeInterval(86_400) }

    @Test func startingABookSetsTheStartDate() {
        let book = Book(title: "Emma", author: "Jane Austen")
        book.setStatus(.reading, now: monday)
        #expect(book.status == .reading)
        #expect(book.dateStarted == monday)
        #expect(book.dateFinished == nil)
    }

    @Test func finishingKeepsTheOriginalStartDate() {
        let book = Book(title: "Emma", author: "Jane Austen")
        book.setStatus(.reading, now: monday)
        book.setStatus(.read, now: tuesday)
        #expect(book.dateStarted == monday)
        #expect(book.dateFinished == tuesday)
    }

    @Test func markingReadDirectlySetsBothDates() {
        let book = Book(title: "Emma", author: "Jane Austen")
        book.setStatus(.read, now: monday)
        #expect(book.dateStarted == monday)
        #expect(book.dateFinished == monday)
    }

    @Test func movingBackToWantToReadClearsDates() {
        let book = Book(title: "Emma", author: "Jane Austen")
        book.setStatus(.read, now: monday)
        book.setStatus(.wantToRead, now: tuesday)
        #expect(book.dateStarted == nil)
        #expect(book.dateFinished == nil)
    }

    @Test func dnfKeepsStartDateButNoFinishDate() {
        let book = Book(title: "Emma", author: "Jane Austen")
        book.setStatus(.reading, now: monday)
        book.setStatus(.dnf, now: tuesday)
        #expect(book.status == .dnf)
        #expect(book.dateStarted == monday)
        #expect(book.dateFinished == nil)
    }
}

struct BookDraftTests {
    @Test func titleIsRequired() {
        var draft = BookDraft()
        #expect(!draft.isValid)
        draft.title = "   "
        #expect(!draft.isValid)
        draft.title = "Emma"
        #expect(draft.isValid)
    }

    @Test func numbersMustMakeSenseWhenFilledIn() {
        var draft = BookDraft()
        draft.title = "Emma"
        draft.pageCountText = "abc"
        #expect(!draft.isValid)
        draft.pageCountText = "0"
        #expect(!draft.isValid)
        draft.pageCountText = "474"
        #expect(draft.isValid)
        #expect(draft.pageCount == 474)

        draft.yearText = "99999"
        #expect(!draft.isValid)
        draft.yearText = "1815"
        #expect(draft.isValid)
        #expect(draft.publishedYear == 1815)
    }

    @Test func prefillsFromSearchResult() {
        let result = BookSearchResult(
            source: .googleBooks,
            sourceID: "g1",
            title: "Emma",
            authors: ["Jane Austen"],
            isbn13: "9780141439587",
            pageCount: 474,
            publishedYear: 1815,
            publisher: "Penguin",
            summary: "Matchmaking.",
            coverURL: URL(string: "https://example.com/emma.jpg")
        )
        let draft = BookDraft(result: result)
        #expect(draft.title == "Emma")
        #expect(draft.author == "Jane Austen")
        #expect(draft.pageCountText == "474")
        #expect(draft.yearText == "1815")
        #expect(draft.source == .googleBooks)
        #expect(draft.isValid)
    }

    @Test func makesABookWithTrimmedValuesAndStatusDates() {
        var draft = BookDraft()
        draft.title = "  Emma  "
        draft.author = " Jane Austen "
        draft.pageCountText = "474"
        draft.publisher = "   "
        draft.status = .reading
        draft.format = .hardcover

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let book = draft.makeBook(now: now)
        #expect(book.title == "Emma")
        #expect(book.author == "Jane Austen")
        #expect(book.pageCount == 474)
        #expect(book.publisher == nil)
        #expect(book.status == .reading)
        #expect(book.format == .hardcover)
        #expect(book.dateStarted == now)
        #expect(book.dateAdded == now)
    }

    @Test func roundTripsThroughEditing() {
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        var draft = BookDraft(book: book)
        draft.title = "Emma (Annotated)"
        draft.status = .read
        draft.apply(to: book)
        #expect(book.title == "Emma (Annotated)")
        #expect(book.status == .read)
        #expect(book.dateFinished != nil)
        #expect(book.pageCount == 474)
    }
}

struct ShelfOrderingTests {
    @Test func readingFirstThenReadThenWantToReadAndNoDNF() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tbr = Book(title: "TBR", author: "A", dateAdded: now)
        let oldRead = Book(title: "Old read", author: "B", dateAdded: now)
        oldRead.setStatus(.read, now: now.addingTimeInterval(-1_000))
        let newRead = Book(title: "New read", author: "C", dateAdded: now)
        newRead.setStatus(.read, now: now)
        let reading = Book(title: "Reading", author: "D", dateAdded: now)
        reading.setStatus(.reading, now: now)
        let dnf = Book(title: "DNF", author: "E", dateAdded: now)
        dnf.setStatus(.dnf, now: now)

        let ordered = ShelfOrdering.sorted([tbr, oldRead, dnf, newRead, reading])
        #expect(ordered.map(\.title) == ["Reading", "New read", "Old read", "TBR"])
    }

    @Test func demoLibraryHasEveryStatus() {
        let statuses = Set(DemoLibrary.books.indices.map(DemoLibrary.status(at:)))
        #expect(statuses == Set(ReadingStatus.allCases))
    }
}

struct LibraryFilterTests {
    @Test func filtersMatchStatuses() {
        #expect(LibraryFilter.all.matches(.dnf))
        #expect(LibraryFilter.reading.matches(.reading))
        #expect(!LibraryFilter.reading.matches(.read))
        #expect(LibraryFilter.dnf.matches(.dnf))
    }
}
