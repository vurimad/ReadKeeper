import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Spreadsheet export: one row per book, readable anywhere.
enum LibraryCSVExport {
    static let header = [
        "Title", "Author", "ISBN13", "Pages", "Year Published", "Publisher", "Format", "Status",
        "Rating", "Spice Level", "Tropes", "Tags", "Review", "Date Added", "Date Started", "Date Finished",
        "Progress", "Progress Unit",
    ]

    static func csv(for books: [Book]) -> String {
        let sorted = books.sorted { $0.dateAdded < $1.dateAdded }
        let rows: [[String]] = sorted.map(row(for:))
        return CSVWriter.document(header: header, rows: rows)
    }

    /// One spreadsheet row, built step by step (a single big literal is too slow for the compiler).
    private static func row(for book: Book) -> [String] {
        let hasProgress = book.progressValue > 0
        var fields: [String] = []
        fields.append(book.title)
        fields.append(book.author)
        fields.append(book.isbn13 ?? "")
        fields.append(book.pageCount.map { String($0) } ?? "")
        fields.append(book.publishedYear.map { String($0) } ?? "")
        fields.append(book.publisher ?? "")
        fields.append(book.format.title)
        fields.append(book.status.title)
        fields.append(book.rating.map { formatNumber($0) } ?? "")
        fields.append(book.spiceLevel.map { String($0) } ?? "")
        fields.append(book.tropes.joined(separator: ", "))
        fields.append(book.tags.joined(separator: ", "))
        fields.append(book.review ?? "")
        fields.append(day(book.dateAdded))
        fields.append(book.dateStarted.map { day($0) } ?? "")
        fields.append(book.dateFinished.map { day($0) } ?? "")
        fields.append(hasProgress ? formatNumber(book.progressValue) : "")
        fields.append(hasProgress ? book.progressUnit.title : "")
        return fields
    }

    /// "2026/11/19", the same style Goodreads uses, so other apps can import it back.
    static func day(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d/%02d/%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

// MARK: - Full backup (JSON)

/// Everything needed to rebuild the library, including reading history and quotes.
/// Cover images are not included (they're re-downloaded from the catalogs).
struct LibraryBackup: Codable, Sendable {
    static let currentVersion = 1

    var version: Int = LibraryBackup.currentVersion
    var exportedAt: Date
    var books: [BookRecord]

    struct BookRecord: Codable, Sendable {
        var id: UUID
        var title: String
        var author: String
        var isbn13: String?
        var pageCount: Int?
        var publishedYear: Int?
        var publisher: String?
        var summary: String?
        var coverURLString: String?
        var statusRaw: String
        var formatRaw: String
        var sourceRaw: String
        var sourceID: String?
        var dateAdded: Date
        var dateStarted: Date?
        var dateFinished: Date?
        var progressUnitRaw: String
        var progressValue: Double
        var totalMinutes: Int?
        var playbackSpeed: Double
        var rating: Double?
        var review: String?
        var spiceLevel: Int?
        var tropes: [String]
        var tags: [String]
        var shelfOrder: Double
        var logs: [LogRecord]
        var quotes: [QuoteRecord]
    }

    struct LogRecord: Codable, Sendable {
        var date: Date
        var startValue: Double
        var endValue: Double
        var unitRaw: String
        var playbackSpeed: Double
        var createdAt: Date
    }

    struct QuoteRecord: Codable, Sendable {
        var text: String
        var page: Int?
        var createdAt: Date
    }

    init(books: [Book], exportedAt: Date = .now) {
        self.exportedAt = exportedAt
        self.books = books.map(BookRecord.init(book:))
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> LibraryBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LibraryBackup.self, from: data)
    }

    /// Adds books from the backup that aren't already in the library. Returns how many were restored.
    @discardableResult
    func restore(into context: ModelContext, existingIDs: Set<UUID>) -> Int {
        var restored = 0
        for record in books where !existingIDs.contains(record.id) {
            let book = record.makeBook()
            context.insert(book)
            for log in record.logs {
                let entry = ReadingLog(
                    date: log.date,
                    startValue: log.startValue,
                    endValue: log.endValue,
                    unit: ProgressUnit(rawValue: log.unitRaw) ?? .pages,
                    playbackSpeed: log.playbackSpeed,
                    createdAt: log.createdAt
                )
                context.insert(entry)
                entry.book = book
            }
            for quote in record.quotes {
                let entry = Quote(text: quote.text, page: quote.page, createdAt: quote.createdAt)
                context.insert(entry)
                entry.book = book
            }
            restored += 1
        }
        try? context.save()
        return restored
    }
}

extension LibraryBackup.BookRecord {
    init(book: Book) {
        id = book.id
        title = book.title
        author = book.author
        isbn13 = book.isbn13
        pageCount = book.pageCount
        publishedYear = book.publishedYear
        publisher = book.publisher
        summary = book.summary
        coverURLString = book.coverURLString
        statusRaw = book.statusRaw
        formatRaw = book.formatRaw
        sourceRaw = book.sourceRaw
        sourceID = book.sourceID
        dateAdded = book.dateAdded
        dateStarted = book.dateStarted
        dateFinished = book.dateFinished
        progressUnitRaw = book.progressUnitRaw
        progressValue = book.progressValue
        totalMinutes = book.totalMinutes
        playbackSpeed = book.playbackSpeed
        rating = book.rating
        review = book.review
        spiceLevel = book.spiceLevel
        tropes = book.tropes
        tags = book.tags
        shelfOrder = book.shelfOrder
        logs = (book.readingLogs ?? [])
            .sorted { $0.date < $1.date }
            .map {
                LibraryBackup.LogRecord(
                    date: $0.date, startValue: $0.startValue, endValue: $0.endValue,
                    unitRaw: $0.unitRaw, playbackSpeed: $0.playbackSpeed, createdAt: $0.createdAt
                )
            }
        quotes = (book.quotes ?? [])
            .sorted { $0.createdAt < $1.createdAt }
            .map { LibraryBackup.QuoteRecord(text: $0.text, page: $0.page, createdAt: $0.createdAt) }
    }

    func makeBook() -> Book {
        let book = Book(
            title: title,
            author: author,
            isbn13: isbn13,
            pageCount: pageCount,
            publishedYear: publishedYear,
            publisher: publisher,
            summary: summary,
            coverURLString: coverURLString,
            dateAdded: dateAdded
        )
        book.id = id
        book.statusRaw = statusRaw
        book.formatRaw = formatRaw
        book.sourceRaw = sourceRaw
        book.sourceID = sourceID
        book.dateStarted = dateStarted
        book.dateFinished = dateFinished
        book.progressUnitRaw = progressUnitRaw
        book.progressValue = progressValue
        book.totalMinutes = totalMinutes
        book.playbackSpeed = playbackSpeed
        book.rating = rating
        book.review = review
        book.spiceLevel = spiceLevel
        book.tropes = tropes
        book.tags = tags
        book.shelfOrder = shelfOrder
        return book
    }
}

// MARK: - File wrapper for the system "Save to Files" sheet

struct ExportFile: FileDocument {
    static let readableContentTypes: [UTType] = [.commaSeparatedText, .json]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
