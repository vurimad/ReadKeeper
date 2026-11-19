import Foundation
import Testing
@testable import ReadKeeper

private let openLibraryJSON = """
{
  "numFound": 2,
  "docs": [
    {
      "key": "/works/OL66554W",
      "title": "Pride and Prejudice",
      "author_name": ["Jane Austen"],
      "first_publish_year": 1813,
      "isbn": ["0141439513", "9780141439518"],
      "number_of_pages_median": 279,
      "cover_i": 14348537,
      "publisher": ["Penguin Classics"]
    },
    { "key": "/works/OL1W", "title": "" },
    { "key": "/works/OL2W", "title": "Untraceable Book" }
  ]
}
"""

private let googleBooksJSON = """
{
  "items": [
    {
      "id": "s1gVAAAAYAAJ",
      "volumeInfo": {
        "title": "Pride and Prejudice",
        "authors": ["Jane Austen"],
        "publisher": "Penguin",
        "publishedDate": "2003-04-29",
        "description": "A classic novel.",
        "pageCount": 480,
        "industryIdentifiers": [
          { "type": "ISBN_10", "identifier": "0141439513" },
          { "type": "ISBN_13", "identifier": "9780141439518" }
        ],
        "imageLinks": { "thumbnail": "http://books.google.com/books/content?id=s1gVAAAAYAAJ&printsec=frontcover&img=1&zoom=1&edge=curl" }
      }
    },
    {
      "id": "abc123",
      "volumeInfo": { "title": "Emma", "authors": ["Jane Austen"], "pageCount": 0 }
    }
  ]
}
"""

struct OpenLibraryParsingTests {
    @Test func parsesDocsAndSkipsEmptyTitles() throws {
        let results = try OpenLibraryClient.parseSearch(Data(openLibraryJSON.utf8))
        #expect(results.count == 2)

        let first = try #require(results.first)
        #expect(first.title == "Pride and Prejudice")
        #expect(first.authors == ["Jane Austen"])
        #expect(first.isbn13 == "9780141439518")
        #expect(first.pageCount == 279)
        #expect(first.publishedYear == 1813)
        #expect(first.publisher == "Penguin Classics")
        #expect(first.coverURL?.absoluteString == "https://covers.openlibrary.org/b/id/14348537-L.jpg")
        #expect(first.source == .openLibrary)

        #expect(results[1].coverURL == nil)
        #expect(results[1].isbn13 == nil)
    }

    @Test func buildsISBNOrTextQueries() {
        let isbnURL = OpenLibraryClient.searchURL(for: "978-0-14-143951-8").absoluteString
        #expect(isbnURL.contains("isbn=9780141439518"))

        let textURL = OpenLibraryClient.searchURL(for: "pride and prejudice").absoluteString
        #expect(textURL.contains("q=pride%20and%20prejudice"))
        #expect(textURL.contains("limit=15"))
    }
}

struct GoogleBooksParsingTests {
    @Test func parsesVolumes() throws {
        let results = try GoogleBooksClient.parseSearch(Data(googleBooksJSON.utf8))
        #expect(results.count == 2)

        let first = try #require(results.first)
        #expect(first.isbn13 == "9780141439518")
        #expect(first.publishedYear == 2003)
        #expect(first.pageCount == 480)
        #expect(first.summary == "A classic novel.")
        let cover = try #require(first.coverURL?.absoluteString)
        #expect(cover.hasPrefix("https://"))
        #expect(!cover.contains("edge=curl"))

        // A page count of 0 means "unknown".
        #expect(results[1].pageCount == nil)
    }

    @Test func emptyResponseGivesNoResults() throws {
        #expect(try GoogleBooksClient.parseSearch(Data("{}".utf8)).isEmpty)
    }

    @Test func buildsISBNQuery() {
        let url = GoogleBooksClient.searchURL(for: "0141439513").absoluteString
        #expect(url.contains("q=isbn:9780141439518"))
    }
}

struct BookSearchMergeTests {
    private func result(
        _ source: BookSearchResult.Source,
        _ id: String,
        title: String,
        author: String,
        isbn: String? = nil,
        pages: Int? = nil,
        cover: String? = nil
    ) -> BookSearchResult {
        BookSearchResult(
            source: source,
            sourceID: id,
            title: title,
            authors: [author],
            isbn13: isbn,
            pageCount: pages,
            coverURL: cover.flatMap(URL.init(string:))
        )
    }

    @Test func mergesSameISBNAndFillsMissingDetails() {
        let google = [result(.googleBooks, "g1", title: "Pride and Prejudice", author: "Jane Austen", isbn: "9780141439518", pages: nil)]
        let openLibrary = [result(.openLibrary, "o1", title: "Pride and Prejudice", author: "Jane Austen", isbn: "9780141439518", pages: 279, cover: "https://example.com/c.jpg")]

        let merged = BookSearchService.merge(google: google, openLibrary: openLibrary)
        #expect(merged.count == 1)
        #expect(merged[0].pageCount == 279)
        #expect(merged[0].coverURL?.absoluteString == "https://example.com/c.jpg")
    }

    @Test func mergesSameTitleAndAuthorIgnoringCaseAccentsAndSubtitles() {
        let google = [result(.googleBooks, "g1", title: "Jane Eyre: An Autobiography", author: "Charlotte Brontë")]
        let openLibrary = [result(.openLibrary, "o1", title: "jane eyre", author: "Charlotte Bronte")]
        #expect(BookSearchService.merge(google: google, openLibrary: openLibrary).count == 1)
    }

    @Test func keepsDifferentBooksAndInterleavesSources() {
        let google = [
            result(.googleBooks, "g1", title: "Emma", author: "Jane Austen"),
            result(.googleBooks, "g2", title: "Persuasion", author: "Jane Austen"),
        ]
        let openLibrary = [result(.openLibrary, "o1", title: "Dracula", author: "Bram Stoker")]
        let merged = BookSearchService.merge(google: google, openLibrary: openLibrary)
        #expect(merged.map(\.title) == ["Emma", "Dracula", "Persuasion"])
    }
}

/// Canned network responses for testing the search service without the internet.
private struct StubHTTPClient: HTTPClient {
    let googleData: Data?
    let openLibraryData: Data?

    func get(_ url: URL) async throws -> Data {
        let data = url.host() == "www.googleapis.com" ? googleData : openLibraryData
        guard let data else { throw HTTPClientError.badStatus(503) }
        return data
    }
}

struct BookSearchServiceTests {
    @Test func combinesBothCatalogs() async throws {
        let service = BookSearchService(http: StubHTTPClient(
            googleData: Data(googleBooksJSON.utf8),
            openLibraryData: Data(openLibraryJSON.utf8)
        ))
        let results = try await service.search("pride")
        // Pride and Prejudice appears in both catalogs and is merged.
        #expect(results.filter { $0.title == "Pride and Prejudice" }.count == 1)
        #expect(results.contains { $0.title == "Emma" })
        #expect(results.contains { $0.title == "Untraceable Book" })
    }

    @Test func stillWorksWhenOneCatalogIsDown() async throws {
        let service = BookSearchService(http: StubHTTPClient(googleData: nil, openLibraryData: Data(openLibraryJSON.utf8)))
        let results = try await service.search("pride")
        #expect(results.count == 2)
    }

    @Test func failsWhenBothCatalogsAreDown() async {
        let service = BookSearchService(http: StubHTTPClient(googleData: nil, openLibraryData: nil))
        await #expect(throws: BookSearchError.catalogsUnavailable) {
            try await service.search("pride")
        }
    }

    @Test func ignoresVeryShortQueries() async throws {
        let service = BookSearchService(http: StubHTTPClient(googleData: nil, openLibraryData: nil))
        #expect(try await service.search(" a ").isEmpty)
    }
}
