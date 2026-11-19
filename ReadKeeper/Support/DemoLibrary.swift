import Foundation
import SwiftData

/// Demo books (public-domain classics) for previews and CI screenshots only.
/// Never shown to real users: only loaded with the `-RKDemoShelf` launch argument in Debug builds.
enum DemoLibrary {
    static let books: [ShelfBook] = [
        ShelfBook(title: "Pride and Prejudice", author: "Jane Austen", pageCount: 432),
        ShelfBook(title: "Moby-Dick", author: "Herman Melville", pageCount: 635),
        ShelfBook(title: "Jane Eyre", author: "Charlotte Brontë", pageCount: 532),
        ShelfBook(title: "Frankenstein", author: "Mary Shelley", pageCount: 280),
        ShelfBook(title: "Dracula", author: "Bram Stoker", pageCount: 418),
        ShelfBook(title: "Little Women", author: "Louisa May Alcott", pageCount: 759),
        ShelfBook(title: "The Odyssey", author: "Homer", pageCount: 541),
        ShelfBook(title: "Wuthering Heights", author: "Emily Brontë", pageCount: 416),
        ShelfBook(title: "Emma", author: "Jane Austen", pageCount: 474),
        ShelfBook(title: "Middlemarch", author: "George Eliot", pageCount: 880),
        ShelfBook(title: "The Great Gatsby", author: "F. Scott Fitzgerald", pageCount: 180),
        ShelfBook(title: "Anna Karenina", author: "Leo Tolstoy", pageCount: 864),
        ShelfBook(title: "Persuasion", author: "Jane Austen", pageCount: 249),
        ShelfBook(title: "The Secret Garden", author: "Frances Hodgson Burnett", pageCount: 331),
        ShelfBook(title: "Treasure Island", author: "Robert Louis Stevenson", pageCount: 292),
        ShelfBook(title: "A Room with a View", author: "E. M. Forster", pageCount: 256),
        ShelfBook(title: "The Picture of Dorian Gray", author: "Oscar Wilde", pageCount: 254),
        ShelfBook(title: "Great Expectations", author: "Charles Dickens", pageCount: 505),
        ShelfBook(title: "Alice's Adventures in Wonderland", author: "Lewis Carroll", pageCount: 200),
        ShelfBook(title: "The Count of Monte Cristo", author: "Alexandre Dumas", pageCount: 1276),
        ShelfBook(title: "Sense and Sensibility", author: "Jane Austen", pageCount: 409),
        ShelfBook(title: "The Wind in the Willows", author: "Kenneth Grahame", pageCount: 224),
        ShelfBook(title: "Anne of Green Gables", author: "L. M. Montgomery", pageCount: 320),
        ShelfBook(title: "Peter Pan", author: "J. M. Barrie", pageCount: 184),
    ]

    /// Status for the demo book at `index`: 2 reading, then mostly read, the last few want-to-read, one DNF.
    static func status(at index: Int) -> ReadingStatus {
        switch index {
        case 0..<2: .reading
        case 12: .dnf
        case 0..<19: .read
        default: .wantToRead
        }
    }

    @MainActor
    static func seed(into context: ModelContext, now: Date = .now) {
        let day: TimeInterval = 86_400
        for (index, item) in books.enumerated() {
            let book = Book(
                title: item.title,
                author: item.author,
                pageCount: item.pageCount,
                format: index % 4 == 3 ? .hardcover : .paperback,
                dateAdded: now.addingTimeInterval(-Double(index) * 3 * day)
            )
            book.setStatus(status(at: index), now: now.addingTimeInterval(-Double(index) * 2 * day))
            context.insert(book)
        }
        try? context.save()
    }
}
