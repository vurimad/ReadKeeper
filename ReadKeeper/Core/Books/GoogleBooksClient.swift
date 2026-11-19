import Foundation

/// Searches the Google Books catalog. Works without an API key at normal usage levels.
struct GoogleBooksClient: Sendable {
    let http: any HTTPClient
    var limit = 15

    func search(_ query: String) async throws -> [BookSearchResult] {
        let data = try await http.get(Self.searchURL(for: query, limit: limit))
        return try Self.parseSearch(data)
    }

    static func searchURL(for query: String, limit: Int = 15) -> URL {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        let q = ISBN.normalized(query).map { "isbn:\($0)" } ?? query.trimmed
        components.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "maxResults", value: String(limit)),
            URLQueryItem(name: "printType", value: "books"),
        ]
        return components.url!
    }

    static func parseSearch(_ data: Data) throws -> [BookSearchResult] {
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return (response.items ?? []).compactMap { item in
            let info = item.volumeInfo
            guard let title = info.title?.nilIfBlank else { return nil }
            let identifiers = info.industryIdentifiers ?? []
            let isbnCandidates = identifiers.filter { $0.type == "ISBN_13" }.map(\.identifier)
                + identifiers.filter { $0.type == "ISBN_10" }.map(\.identifier)
            return BookSearchResult(
                source: .googleBooks,
                sourceID: item.id,
                title: title,
                authors: info.authors ?? [],
                isbn13: ISBN.preferred(from: isbnCandidates),
                pageCount: info.pageCount.flatMap { $0 > 0 ? $0 : nil },
                publishedYear: info.publishedDate.flatMap { Int($0.prefix(4)) },
                publisher: info.publisher?.nilIfBlank,
                summary: info.description?.nilIfBlank,
                coverURL: coverURL(from: info.imageLinks)
            )
        }
    }

    /// Google returns http thumbnails with a page-curl effect; ask for https and a flat image.
    static func coverURL(from links: ImageLinks?) -> URL? {
        guard let raw = links?.thumbnail ?? links?.smallThumbnail else { return nil }
        let cleaned = raw
            .replacingOccurrences(of: "http://", with: "https://")
            .replacingOccurrences(of: "&edge=curl", with: "")
        return URL(string: cleaned)
    }

    struct SearchResponse: Decodable {
        let items: [Item]?
    }

    struct Item: Decodable {
        let id: String
        let volumeInfo: VolumeInfo
    }

    struct VolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let publisher: String?
        let publishedDate: String?
        let description: String?
        let pageCount: Int?
        let industryIdentifiers: [Identifier]?
        let imageLinks: ImageLinks?
    }

    struct Identifier: Decodable {
        let type: String
        let identifier: String
    }

    struct ImageLinks: Decodable {
        let thumbnail: String?
        let smallThumbnail: String?
    }
}
