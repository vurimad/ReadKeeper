import Foundation

/// Searches the free Open Library catalog (openlibrary.org). No API key needed.
struct OpenLibraryClient: Sendable {
    let http: any HTTPClient
    var limit = 15

    func search(_ query: String) async throws -> [BookSearchResult] {
        let data = try await http.get(Self.searchURL(for: query, limit: limit))
        return try Self.parseSearch(data)
    }

    static func searchURL(for query: String, limit: Int = 15) -> URL {
        var components = URLComponents(string: "https://openlibrary.org/search.json")!
        var items: [URLQueryItem]
        if let isbn = ISBN.normalized(query) {
            items = [URLQueryItem(name: "isbn", value: isbn)]
        } else {
            items = [URLQueryItem(name: "q", value: query.trimmed)]
        }
        items.append(URLQueryItem(
            name: "fields",
            value: "key,title,author_name,first_publish_year,isbn,number_of_pages_median,cover_i,publisher"
        ))
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        components.queryItems = items
        return components.url!
    }

    static func parseSearch(_ data: Data) throws -> [BookSearchResult] {
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.docs.compactMap { doc in
            guard let title = doc.title?.nilIfBlank else { return nil }
            return BookSearchResult(
                source: .openLibrary,
                sourceID: doc.key ?? title,
                title: title,
                authors: doc.authorName ?? [],
                isbn13: ISBN.preferred(from: doc.isbn ?? []),
                pageCount: doc.numberOfPagesMedian,
                publishedYear: doc.firstPublishYear,
                publisher: doc.publisher?.first,
                summary: nil,
                coverURL: doc.coverI.flatMap { URL(string: "https://covers.openlibrary.org/b/id/\($0)-L.jpg") }
            )
        }
    }

    struct SearchResponse: Decodable {
        let docs: [Doc]
    }

    struct Doc: Decodable {
        let key: String?
        let title: String?
        let authorName: [String]?
        let firstPublishYear: Int?
        let isbn: [String]?
        let numberOfPagesMedian: Int?
        let coverI: Int?
        let publisher: [String]?

        enum CodingKeys: String, CodingKey {
            case key, title, isbn, publisher
            case authorName = "author_name"
            case firstPublishYear = "first_publish_year"
            case numberOfPagesMedian = "number_of_pages_median"
            case coverI = "cover_i"
        }
    }
}
