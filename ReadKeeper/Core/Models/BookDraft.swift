import Foundation

/// Editable copy of a book's details, used by the add/edit form.
/// A plain value, so validation and conversion can be tested without the database.
struct BookDraft: Equatable, Sendable {
    var title: String = ""
    var author: String = ""
    var pageCountText: String = ""
    var yearText: String = ""
    var publisher: String = ""
    var isbn13: String?
    var summary: String?
    var coverURL: URL?
    var coverImageData: Data?
    var status: ReadingStatus = .wantToRead
    var format: BookFormat = .paperback
    var source: BookSource = .manual
    var sourceID: String?

    static let maxPages = 20_000

    init() {}

    init(result: BookSearchResult) {
        title = result.title
        author = result.authorLine
        pageCountText = result.pageCount.map(String.init) ?? ""
        yearText = result.publishedYear.map(String.init) ?? ""
        publisher = result.publisher ?? ""
        isbn13 = result.isbn13
        summary = result.summary
        coverURL = result.coverURL
        source = result.source == .openLibrary ? .openLibrary : .googleBooks
        sourceID = result.sourceID
    }

    init(book: Book) {
        title = book.title
        author = book.author
        pageCountText = book.pageCount.map(String.init) ?? ""
        yearText = book.publishedYear.map(String.init) ?? ""
        publisher = book.publisher ?? ""
        isbn13 = book.isbn13
        summary = book.summary
        coverURL = book.coverURL
        coverImageData = book.coverImageData
        status = book.status
        format = book.format
        source = book.source
        sourceID = book.sourceID
    }

    // MARK: Parsing and validation

    var pageCount: Int? {
        guard let value = Int(pageCountText.trimmed), value > 0, value <= Self.maxPages else { return nil }
        return value
    }

    var publishedYear: Int? {
        guard let value = Int(yearText.trimmed), value > 0, value <= Self.currentYear + 1 else { return nil }
        return value
    }

    var hasCover: Bool { coverImageData != nil || coverURL != nil }

    /// Empty optional fields are fine; filled-in numbers must make sense.
    var isValid: Bool {
        guard title.nilIfBlank != nil else { return false }
        if pageCountText.nilIfBlank != nil && pageCount == nil { return false }
        if yearText.nilIfBlank != nil && publishedYear == nil { return false }
        return true
    }

    var validationMessage: String? {
        if title.nilIfBlank == nil { return "Add a title." }
        if pageCountText.nilIfBlank != nil && pageCount == nil { return "Pages must be a number between 1 and \(Self.maxPages)." }
        if yearText.nilIfBlank != nil && publishedYear == nil { return "Year must be a valid year." }
        return nil
    }

    // MARK: Converting to and from Book

    func makeBook(now: Date = .now) -> Book {
        let book = Book(
            title: title.trimmed,
            author: author.trimmed,
            isbn13: isbn13,
            pageCount: pageCount,
            publishedYear: publishedYear,
            publisher: publisher.nilIfBlank,
            summary: summary?.nilIfBlank,
            coverURLString: coverURL?.absoluteString,
            coverImageData: coverImageData,
            status: .wantToRead,
            format: format,
            source: source,
            sourceID: sourceID,
            dateAdded: now
        )
        book.setStatus(status, now: now)
        return book
    }

    func apply(to book: Book, now: Date = .now) {
        book.title = title.trimmed
        book.author = author.trimmed
        book.pageCount = pageCount
        book.publishedYear = publishedYear
        book.publisher = publisher.nilIfBlank
        book.isbn13 = isbn13
        book.summary = summary?.nilIfBlank
        book.coverURLString = coverURL?.absoluteString
        book.coverImageData = coverImageData
        book.format = format
        if book.status != status {
            book.setStatus(status, now: now)
        }
    }

    private static var currentYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: .now)
    }
}
