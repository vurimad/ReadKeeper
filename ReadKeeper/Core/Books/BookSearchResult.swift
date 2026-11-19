import Foundation

/// A book found in an online catalog, before it's added to the library.
struct BookSearchResult: Identifiable, Hashable, Sendable {
    enum Source: String, Sendable {
        case openLibrary
        case googleBooks
    }

    let source: Source
    let sourceID: String
    var title: String
    var authors: [String]
    var isbn13: String?
    var pageCount: Int?
    var publishedYear: Int?
    var publisher: String?
    var summary: String?
    var coverURL: URL?

    var id: String { "\(source.rawValue):\(sourceID)" }

    var authorLine: String {
        authors.isEmpty ? "" : authors.joined(separator: ", ")
    }

    /// Fills in details this result is missing from another result for the same book.
    func filling(from other: BookSearchResult) -> BookSearchResult {
        var merged = self
        if merged.authors.isEmpty { merged.authors = other.authors }
        merged.isbn13 = merged.isbn13 ?? other.isbn13
        merged.pageCount = merged.pageCount ?? other.pageCount
        merged.publishedYear = merged.publishedYear ?? other.publishedYear
        merged.publisher = merged.publisher ?? other.publisher
        merged.summary = merged.summary ?? other.summary
        merged.coverURL = merged.coverURL ?? other.coverURL
        return merged
    }
}
