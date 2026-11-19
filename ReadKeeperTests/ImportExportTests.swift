import Foundation
import SwiftData
import Testing
@testable import ReadKeeper

struct CSVParserTests {
    @Test func plainRows() {
        #expect(CSVParser.parseRows("a,b,c\n1,2,3\n") == [["a", "b", "c"], ["1", "2", "3"]])
    }

    @Test func quotedCommasQuotesAndLineBreaks() {
        let text = "title,review\n\"Hello, World\",\"She said \"\"hi\"\"\nthen left\"\n"
        #expect(CSVParser.parseRows(text) == [["title", "review"], ["Hello, World", "She said \"hi\"\nthen left"]])
    }

    @Test func windowsLineEndingsByteOrderMarkAndBlankLines() {
        let text = "\u{FEFF}a,b\r\n1,2\r\n\r\n3,4"
        #expect(CSVParser.parseRows(text) == [["a", "b"], ["1", "2"], ["3", "4"]])
    }

    @Test func emptyFieldsAreKept() {
        #expect(CSVParser.parseRows("a,,c\n,,\n") == [["a", "", "c"], ["", "", ""]])
    }

    @Test func tableLooksUpColumnsByName() throws {
        let table = try #require(CSVParser.parseTable("Title, Author\nEmma,Jane Austen\nPersuasion,"))
        #expect(table.hasColumns(["Title", "Author"]))
        #expect(table.value("Author", in: table.rows[0]) == "Jane Austen")
        #expect(table.value("Author", in: table.rows[1]) == nil)
        #expect(table.value("Missing", in: table.rows[0]) == nil)
    }

    @Test func writerRoundTripsThroughTheParser() {
        let rows = [["Emma", "Austen, Jane", "Said \"no\"", "line1\nline2"]]
        let text = CSVWriter.document(header: ["A", "B", "C", "D"], rows: rows)
        #expect(text.hasPrefix("\u{FEFF}"))
        #expect(CSVParser.parseRows(text) == [["A", "B", "C", "D"]] + rows)
    }

    @Test func importDates() {
        let calendar = Calendar.current
        let date = ImportDate.parse("2025/02/14")
        #expect(date.map { calendar.dateComponents([.year, .month, .day], from: $0) } == DateComponents(year: 2025, month: 2, day: 14))
        #expect(ImportDate.parse("2025-02-14 10:31:00") != nil)
        #expect(ImportDate.parse("") == nil)
        #expect(ImportDate.parse("14/02/2025") == nil)
    }
}

struct GoodreadsImportTests {
    private func plan(existing: Set<String> = []) throws -> ImportPlan {
        try LibraryImporter.plan(text: DemoLibrary.sampleGoodreadsCSV, existingKeys: existing)
    }

    @Test func recognizesGoodreadsAndCountsStatuses() throws {
        let plan = try plan()
        #expect(plan.source == .goodreads)
        #expect(plan.books.count == 7)
        #expect(plan.count(of: .read) == 3)
        #expect(plan.count(of: .reading) == 1)
        #expect(plan.count(of: .wantToRead) == 2)
        #expect(plan.count(of: .dnf) == 1)
        #expect(plan.withoutISBN == 1)
    }

    @Test func readsEveryFieldOfARealRow() throws {
        let pride = try #require(try plan().books.first { $0.title == "Pride and Prejudice" })
        #expect(pride.author == "Jane Austen")
        #expect(pride.isbn13 == "9780141439518")
        #expect(pride.rating == 5)
        #expect(pride.pageCount == 480)
        #expect(pride.publishedYear == 1813) // original publication year, not the edition's
        #expect(pride.publisher == "Penguin Classics")
        #expect(pride.format == .paperback)
        #expect(pride.tags == ["classics", "favorites"])
        #expect(pride.review == "Witty, warm and sharp.\n\nLizzie is \"the best\".")
        let finished = try #require(pride.dateFinished)
        #expect(Calendar.current.dateComponents([.year, .month, .day], from: finished) == DateComponents(year: 2025, month: 2, day: 14))
    }

    @Test func mapsBindingsAndShelves() throws {
        let books = try plan().books
        #expect(books.first { $0.title == "Dracula" }?.format == .ebook)
        #expect(books.first { $0.title == "Dracula" }?.rating == nil) // 0 means unrated
        #expect(books.first { $0.title == "Moby-Dick" }?.format == .audiobook)
        #expect(books.first { $0.title == "Moby-Dick" }?.status == .dnf)
        #expect(books.first { $0.title == "Moby-Dick" }?.tags.isEmpty == true)
        #expect(books.first { $0.title == "Wuthering Heights" }?.format == .hardcover)
        #expect(books.first { $0.title == "The Adventures of Huckleberry Finn" }?.isbn13 == nil)
    }

    @Test func skipsBooksAlreadyInTheLibrary() throws {
        let existing = LibraryImporter.matchKeys(title: "Pride & Prejudice: Annotated", author: "jane austen", isbn13: "9780141439518")
        let plan = try plan(existing: existing)
        #expect(plan.books.count == 6)
        #expect(plan.alreadyInLibrary.map(\.title) == ["Pride and Prejudice"])
    }

    @Test func matchesSameBookByTitleAndAuthorWithoutISBN() {
        let library = LibraryImporter.matchKeys(title: "Jane Eyre (Penguin Classics)", author: "Charlotte Bronte", isbn13: nil)
        let imported = LibraryImporter.matchKeys(title: "Jane Eyre", author: "Charlotte Brontë", isbn13: "9780141441146")
        #expect(!library.isDisjoint(with: imported))
    }

    @Test func duplicateRowsInOneFileImportOnce() throws {
        let lines = DemoLibrary.sampleGoodreadsCSV.split(separator: "\n").map(String.init)
        let doubled = ([lines[0], lines[1], lines[1]]).joined(separator: "\n")
        let plan = try LibraryImporter.plan(text: doubled, existingKeys: [])
        #expect(plan.books.count == 1)
        #expect(plan.alreadyInLibrary.count == 1)
    }

    @Test func importedBooksKeepTheirOwnDates() throws {
        let books = try plan().books
        let read = try #require(books.first { $0.title == "Pride and Prejudice" }).makeBook()
        #expect(read.status == .read)
        #expect(read.dateStarted == nil)
        #expect(read.dateFinished != nil)
        #expect(read.progressValue == 480)
        #expect(read.source == .imported)
        #expect(read.coverURLString == "https://covers.openlibrary.org/b/isbn/9780141439518-L.jpg?default=false")

        let reading = try #require(books.first { $0.title == "Dracula" }).makeBook()
        #expect(reading.status == .reading)
        #expect(reading.dateStarted == reading.dateAdded)
        #expect(reading.progressUnit == .percent) // Kindle edition tracks by percent
    }
}

struct StoryGraphImportTests {
    static let csv = #"""
    Title,Authors,Contributors,ISBN/UID,Format,Read Status,Date Added,Last Date Read,Dates Read,Read Count,Moods,Pace,Character- or Plot-Driven?,Strong Character Development?,Loveable Characters?,Diverse Characters?,Flawed Characters?,Star Rating,Review,Content Warnings,Content Warning Description,Tags,Owned?
    Emma,Jane Austen,,9780141439587,paperback,read,2025/01/05,2025/02/01,2025/01/10-2025/02/01,1,"funny, lighthearted",medium,Character,Yes,Yes,No,Yes,4.25,"Delightful, if slow.",,,"classics, comfort",Yes
    Persuasion,Jane Austen,,,audio,currently-reading,2026/11/01,,,0,,,,,,,,,,,,,No
    The Count of Monte Cristo,Alexandre Dumas,,9780140449266,digital,did-not-finish,2026/05/01,,2026/05/02-,0,,,,,,,,,,,,,No
    """#

    @Test func parsesStoryGraphExport() throws {
        let plan = try LibraryImporter.plan(text: Self.csv, existingKeys: [])
        #expect(plan.source == .storyGraph)
        #expect(plan.books.count == 3)

        let emma = try #require(plan.books.first { $0.title == "Emma" })
        #expect(emma.rating == 4.5) // 4.25 rounds to the nearest half star
        #expect(emma.status == .read)
        #expect(emma.tags == ["classics", "comfort"])
        #expect(emma.review == "Delightful, if slow.")
        let calendar = Calendar.current
        #expect(emma.dateStarted.map { calendar.component(.day, from: $0) } == 10)
        #expect(emma.dateFinished.map { calendar.component(.month, from: $0) } == 2)

        let persuasion = try #require(plan.books.first { $0.title == "Persuasion" })
        #expect(persuasion.format == .audiobook)
        #expect(persuasion.status == .reading)

        let monteCristo = try #require(plan.books.first { $0.title == "The Count of Monte Cristo" })
        #expect(monteCristo.status == .dnf)
        #expect(monteCristo.format == .ebook)
        #expect(monteCristo.dateStarted != nil)
    }

    @Test func unknownFilesAreRejectedWithAFriendlyError() {
        #expect(throws: ImportError.unrecognizedFile) {
            try LibraryImporter.plan(text: "Name,Price\nApple,1\n", existingKeys: [])
        }
        #expect(throws: ImportError.emptyFile) {
            try LibraryImporter.plan(text: "", existingKeys: [])
        }
    }

    @Test func ratingRounding() {
        #expect(ImportMapping.rating("3.75") == 4)
        #expect(ImportMapping.rating("3.6") == 3.5)
        #expect(ImportMapping.rating("0") == nil)
        #expect(ImportMapping.rating("abc") == nil)
    }
}

struct ExportAndBackupTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Book.self, ReadingLog.self, Quote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func spreadsheetExportEscapesAndReadsBack() throws {
        let book = Book(title: "Hello, \"World\"", author: "A. Writer", pageCount: 300)
        book.rating = 4.5
        book.tropes = ["Slow burn", "Found family"]
        let csv = LibraryCSVExport.csv(for: [book])
        let table = try #require(CSVParser.parseTable(csv))
        #expect(table.headers == LibraryCSVExport.header)
        let row = try #require(table.rows.first)
        #expect(table.value("Title", in: row) == "Hello, \"World\"")
        #expect(table.value("Rating", in: row) == "4.5")
        #expect(table.value("Tropes", in: row) == "Slow burn, Found family")
        #expect(table.value("Pages", in: row) == "300")
    }

    @Test func fullBackupRoundTripKeepsEverything() throws {
        let source = try makeContext()
        let book = Book(title: "Emma", author: "Jane Austen", pageCount: 474)
        source.insert(book)
        book.logProgress(to: 120, unit: .pages, on: Date(timeIntervalSince1970: 1_700_000_000), context: source)
        book.rating = 4
        book.spiceLevel = 1
        book.tropes = ["Matchmaking"]
        book.shelfOrder = 3
        let quote = Quote(text: "Silly things do cease to be silly.", page: 210)
        source.insert(quote)
        quote.book = book

        let data = try LibraryBackup(books: [book]).encoded()
        let decoded = try LibraryBackup.decode(data)

        let target = try makeContext()
        #expect(decoded.restore(into: target, existingIDs: []) == 1)
        let restored = try #require(try target.fetch(FetchDescriptor<Book>()).first)
        #expect(restored.id == book.id)
        #expect(restored.title == "Emma")
        #expect(restored.status == .reading)
        #expect(restored.progressValue == 120)
        #expect(restored.rating == 4)
        #expect(restored.spiceLevel == 1)
        #expect(restored.tropes == ["Matchmaking"])
        #expect(restored.shelfOrder == 3)
        #expect(restored.readingLogs?.count == 1)
        #expect(restored.quotes?.first?.page == 210)

        // Restoring the same backup again doesn't duplicate anything.
        #expect(decoded.restore(into: target, existingIDs: [book.id]) == 0)
    }
}
