import Foundation
import SwiftData

/// A book in the user's library.
///
/// Kept compatible with iCloud sync (CloudKit) from day one: every stored property has a default
/// or is optional, there are no unique constraints, and enums are stored as raw strings.
@Model
final class Book {
    var id: UUID = UUID()
    var title: String = ""
    var author: String = ""
    var isbn13: String?
    var pageCount: Int?
    var publishedYear: Int?
    var publisher: String?
    var summary: String?
    var coverURLString: String?
    @Attribute(.externalStorage) var coverImageData: Data?

    var statusRaw: String = ReadingStatus.wantToRead.rawValue
    var formatRaw: String = BookFormat.paperback.rawValue
    var sourceRaw: String = BookSource.manual.rawValue
    var sourceID: String?

    var dateAdded: Date = Date()
    var dateStarted: Date?
    var dateFinished: Date?

    init(
        title: String,
        author: String,
        isbn13: String? = nil,
        pageCount: Int? = nil,
        publishedYear: Int? = nil,
        publisher: String? = nil,
        summary: String? = nil,
        coverURLString: String? = nil,
        coverImageData: Data? = nil,
        status: ReadingStatus = .wantToRead,
        format: BookFormat = .paperback,
        source: BookSource = .manual,
        sourceID: String? = nil,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.author = author
        self.isbn13 = isbn13
        self.pageCount = pageCount
        self.publishedYear = publishedYear
        self.publisher = publisher
        self.summary = summary
        self.coverURLString = coverURLString
        self.coverImageData = coverImageData
        self.statusRaw = status.rawValue
        self.formatRaw = format.rawValue
        self.sourceRaw = source.rawValue
        self.sourceID = sourceID
        self.dateAdded = dateAdded
    }

    var status: ReadingStatus {
        ReadingStatus(rawValue: statusRaw) ?? .wantToRead
    }

    var format: BookFormat {
        get { BookFormat(rawValue: formatRaw) ?? .paperback }
        set { formatRaw = newValue.rawValue }
    }

    var source: BookSource {
        BookSource(rawValue: sourceRaw) ?? .manual
    }

    var coverURL: URL? {
        coverURLString.flatMap(URL.init(string:))
    }

    var displayAuthor: String {
        author.isEmpty ? "Unknown Author" : author
    }

    /// Changes the reading status and keeps the start and finish dates consistent.
    func setStatus(_ newStatus: ReadingStatus, now: Date = .now) {
        switch newStatus {
        case .wantToRead:
            dateStarted = nil
            dateFinished = nil
        case .reading:
            dateStarted = dateStarted ?? now
            dateFinished = nil
        case .read:
            dateStarted = dateStarted ?? now
            dateFinished = dateFinished ?? now
        case .dnf:
            dateFinished = nil
        }
        statusRaw = newStatus.rawValue
    }

    /// Lightweight value used to draw the book's spine.
    var shelfBook: ShelfBook {
        ShelfBook(id: id, title: title, author: displayAuthor, pageCount: pageCount)
    }
}
