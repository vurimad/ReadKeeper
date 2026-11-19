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

    static let yearlyGoal = 24

    /// Half-star ratings handed out to the finished demo books.
    private static let ratings: [Double] = [5, 4.5, 4, 3.5, 5, 4, 4.5, 3, 4, 5, 3.5, 4.5, 4, 5, 4.5, 4, 3.5]

    @MainActor
    static func seed(into context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }

        var finishedCount = 0
        for (index, item) in books.enumerated() {
            let isAudiobook = index == 1
            let book = Book(
                title: item.title,
                author: item.author,
                pageCount: item.pageCount,
                format: isAudiobook ? .audiobook : (index % 4 == 3 ? .hardcover : .paperback),
                dateAdded: daysAgo(index * 3 + 7)
            )
            context.insert(book)

            switch status(at: index) {
            case .reading where isAudiobook:
                book.totalMinutes = 1_460
                book.playbackSpeed = 1.5
                book.logProgress(to: 300, unit: .minutes, on: daysAgo(5), context: context)
                book.logProgress(to: 410, unit: .minutes, on: daysAgo(1), context: context)
            case .reading:
                // Daily reading with one rest day (3 days ago), so the streak shows the forgiving rule.
                for (days, page) in [(6, 40), (5, 85), (4, 120), (2, 160), (1, 200), (0, 245)] {
                    book.logProgress(to: Double(page), unit: .pages, on: daysAgo(days), context: context)
                }
                book.tropes = ["Enemies to lovers", "Slow burn"]
                let quote = Quote(
                    text: "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
                    page: 1
                )
                context.insert(quote)
                quote.book = book
            case .read:
                book.setStatus(.read, now: daysAgo(index * 9))
                book.rating = ratings[finishedCount % ratings.count]
                finishedCount += 1
            case .dnf:
                book.logProgress(to: 60, unit: .pages, on: daysAgo(40), context: context)
                book.setStatus(.dnf, now: daysAgo(38))
            case .wantToRead:
                break
            }
        }

        // A few books with full "thoughts", like a real reader's library.
        applyThoughts(
            to: "Jane Eyre",
            in: context,
            spice: 1,
            tropes: ["Slow burn", "Second chance"],
            tags: ["classics", "book club"],
            review: "Moody, brave and far funnier than I expected. Rochester is a lot, but Jane is the best narrator."
        )
        applyThoughts(to: "Dracula", in: context, spice: 2, tropes: ["Found family"], tags: ["spooky season"], review: nil)
        try? context.save()
    }

    @MainActor
    private static func applyThoughts(
        to title: String,
        in context: ModelContext,
        spice: Int,
        tropes: [String],
        tags: [String],
        review: String?
    ) {
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.title == title })
        guard let book = try? context.fetch(descriptor).first else { return }
        book.spiceLevel = spice
        book.tropes = tropes
        book.tags = tags
        book.review = review
    }
}
