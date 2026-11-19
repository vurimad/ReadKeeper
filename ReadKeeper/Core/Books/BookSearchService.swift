import Foundation

enum BookSearchError: Error, Equatable {
    /// Both catalogs failed (usually no internet connection).
    case catalogsUnavailable
}

/// Searches Google Books and Open Library at the same time, then merges the results.
/// If one catalog fails, results from the other are still shown.
struct BookSearchService: Sendable {
    let googleBooks: GoogleBooksClient
    let openLibrary: OpenLibraryClient

    init(http: any HTTPClient) {
        googleBooks = GoogleBooksClient(http: http)
        openLibrary = OpenLibraryClient(http: http)
    }

    static let live = BookSearchService(http: URLSessionHTTPClient())

    func search(_ query: String) async throws -> [BookSearchResult] {
        let trimmed = query.trimmed
        guard trimmed.count >= 2 else { return [] }

        let google = googleBooks
        let openLibrary = openLibrary
        async let googleResults = Self.attempt { try await google.search(trimmed) }
        async let openLibraryResults = Self.attempt { try await openLibrary.search(trimmed) }
        let (fromGoogle, fromOpenLibrary) = await (googleResults, openLibraryResults)

        try Task.checkCancellation()
        if fromGoogle == nil && fromOpenLibrary == nil {
            throw BookSearchError.catalogsUnavailable
        }
        return Self.merge(google: fromGoogle ?? [], openLibrary: fromOpenLibrary ?? [])
    }

    private static func attempt(
        _ operation: @Sendable () async throws -> [BookSearchResult]
    ) async -> [BookSearchResult]? {
        try? await operation()
    }

    /// Interleaves both lists (keeping each catalog's ranking), then merges duplicates:
    /// same ISBN, or same title and author. Missing details are filled from the duplicate.
    static func merge(google: [BookSearchResult], openLibrary: [BookSearchResult]) -> [BookSearchResult] {
        var interleaved: [BookSearchResult] = []
        for index in 0..<max(google.count, openLibrary.count) {
            if index < google.count { interleaved.append(google[index]) }
            if index < openLibrary.count { interleaved.append(openLibrary[index]) }
        }

        var merged: [BookSearchResult] = []
        var positionByKey: [String: Int] = [:]
        for item in interleaved {
            let keys = dedupeKeys(for: item)
            if let position = keys.lazy.compactMap({ positionByKey[$0] }).first {
                merged[position] = merged[position].filling(from: item)
                for key in dedupeKeys(for: merged[position]) { positionByKey[key] = position }
            } else {
                merged.append(item)
                for key in keys { positionByKey[key] = merged.count - 1 }
            }
        }
        return merged
    }

    static func dedupeKeys(for result: BookSearchResult) -> [String] {
        var keys: [String] = []
        if let isbn = result.isbn13 { keys.append("isbn:\(isbn)") }
        let title = simplified(result.title.split(separator: ":").first.map(String.init) ?? result.title)
        let author = simplified(result.authors.first?.split(separator: " ").last.map(String.init) ?? "")
        if !title.isEmpty { keys.append("work:\(title)|\(author)") }
        return keys
    }

    private static func simplified(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }
}
