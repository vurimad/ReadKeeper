import Foundation

/// Decides which books stand on the shelf and in what order:
/// currently reading first, then finished books (newest first), then want-to-read.
/// Did-not-finish books stay off the shelf.
enum ShelfOrdering {
    static func sorted(_ books: [Book]) -> [Book] {
        books
            .filter { $0.status != .dnf }
            .sorted { lhs, rhs in
                let left = rank(lhs.status)
                let right = rank(rhs.status)
                if left != right { return left < right }
                return sortDate(lhs) > sortDate(rhs)
            }
    }

    private static func rank(_ status: ReadingStatus) -> Int {
        switch status {
        case .reading: 0
        case .read: 1
        case .wantToRead: 2
        case .dnf: 3
        }
    }

    private static func sortDate(_ book: Book) -> Date {
        switch book.status {
        case .reading: book.dateStarted ?? book.dateAdded
        case .read: book.dateFinished ?? book.dateAdded
        case .wantToRead, .dnf: book.dateAdded
        }
    }
}
