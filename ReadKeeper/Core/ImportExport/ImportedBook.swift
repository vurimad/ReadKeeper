import Foundation

enum ImportSource: String, Sendable {
    case goodreads
    case storyGraph

    var title: String {
        switch self {
        case .goodreads: "Goodreads"
        case .storyGraph: "StoryGraph"
        }
    }
}

/// One book read from another app's export, before it's added to the library.
struct ImportedBook: Identifiable, Equatable, Sendable {
    let id = UUID()
    var title: String
    var author: String
    var isbn13: String?
    var pageCount: Int?
    var publishedYear: Int?
    var publisher: String?
    var format: BookFormat = .paperback
    var status: ReadingStatus = .wantToRead
    var rating: Double?
    var review: String?
    var tags: [String] = []
    var dateAdded: Date?
    var dateStarted: Date?
    var dateFinished: Date?

    /// Covers come from Open Library by ISBN; books without an ISBN get a generated cover.
    var coverURL: URL? {
        isbn13.flatMap { URL(string: "https://covers.openlibrary.org/b/isbn/\($0)-L.jpg?default=false") }
    }

    func makeBook(now: Date = .now) -> Book {
        let book = Book(
            title: title,
            author: author,
            isbn13: isbn13,
            pageCount: pageCount,
            publishedYear: publishedYear,
            publisher: publisher,
            coverURLString: coverURL?.absoluteString,
            status: status,
            format: format,
            source: .imported,
            dateAdded: dateAdded ?? now
        )
        // Imported dates are used as-is; we don't invent "started today" for old books.
        book.dateStarted = dateStarted ?? (status == .reading ? (dateAdded ?? now) : nil)
        book.dateFinished = status == .read ? dateFinished : nil
        if status == .read, let total = ProgressMath.total(unit: book.progressUnit, pageCount: pageCount, totalMinutes: nil) {
            book.progressValue = total
        }
        book.rating = rating
        book.review = review
        book.tags = tags
        return book
    }
}

/// Mapping helpers shared by the importers.
enum ImportMapping {
    /// Ratings rounded to the nearest half star; 0 or blank means "not rated".
    static func rating(_ raw: String?) -> Double? {
        guard let value = raw.flatMap({ Double($0.trimmed) }), value > 0 else { return nil }
        return min(max((value * 2).rounded() / 2, 0.5), 5)
    }

    static func format(_ raw: String?) -> BookFormat {
        let value = raw?.lowercased() ?? ""
        if value.contains("audio") { return .audiobook }
        if value.contains("kindle") || value.contains("ebook") || value.contains("e-book")
            || value.contains("digital") || value.contains("nook") || value.contains("kobo") {
            return .ebook
        }
        if value.contains("hardcover") || value.contains("hardback") { return .hardcover }
        return .paperback
    }

    /// Goodreads wraps ISBNs like ="9780141439518" to stop Excel mangling them.
    static func isbn(_ candidates: String?...) -> String? {
        let cleaned = candidates.compactMap { $0?.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "\"", with: "") }
        return ISBN.preferred(from: cleaned)
    }

    static func list(_ raw: String?) -> [String] {
        (raw ?? "").split(separator: ",").reduce(into: [String]()) { result, item in
            result = TagList.adding(String(item), to: result)
        }
    }

    /// Goodreads reviews contain HTML line breaks.
    static func review(_ raw: String?) -> String? {
        raw?
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .nilIfBlank
    }
}
