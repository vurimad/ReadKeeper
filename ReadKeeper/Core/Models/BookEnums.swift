import Foundation

enum ReadingStatus: String, CaseIterable, Identifiable, Codable, Sendable {
    case reading
    case wantToRead
    case read
    case dnf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "Reading"
        case .wantToRead: "Want to Read"
        case .read: "Read"
        case .dnf: "Did Not Finish"
        }
    }

    var shortTitle: String {
        switch self {
        case .dnf: "DNF"
        default: title
        }
    }

    var systemImage: String {
        switch self {
        case .reading: "book"
        case .wantToRead: "bookmark"
        case .read: "checkmark.circle"
        case .dnf: "xmark.circle"
        }
    }
}

enum BookFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case paperback
    case hardcover
    case ebook
    case audiobook

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paperback: "Paperback"
        case .hardcover: "Hardcover"
        case .ebook: "Ebook"
        case .audiobook: "Audiobook"
        }
    }

    var systemImage: String {
        switch self {
        case .paperback: "book.closed"
        case .hardcover: "books.vertical"
        case .ebook: "ipad"
        case .audiobook: "headphones"
        }
    }
}

/// Where a book's details came from.
enum BookSource: String, Codable, Sendable {
    case manual
    case openLibrary
    case googleBooks
    case imported
}
