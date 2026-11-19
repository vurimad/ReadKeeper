import Foundation

/// Reads the CSV from Goodreads: My Books → Import and export → Export Library.
enum GoodreadsImporter {
    static let signatureColumns = ["Title", "Author", "Exclusive Shelf"]
    private static let builtInShelves: Set<String> = ["read", "to-read", "currently-reading"]

    static func books(from table: CSVTable, calendar: Calendar = .current) -> [ImportedBook] {
        table.rows.compactMap { row in
            guard let title = table.value("Title", in: row) else { return nil }
            let shelf = (table.value("Exclusive Shelf", in: row) ?? "to-read").lowercased()
            let year = table.value("Original Publication Year", in: row).flatMap { Int($0) }
                ?? table.value("Year Published", in: row).flatMap { Int($0) }
            let shelves = ImportMapping.list(table.value("Bookshelves", in: row))
                .filter { !builtInShelves.contains($0.lowercased()) && $0.lowercased() != shelf }

            return ImportedBook(
                title: title,
                author: table.value("Author", in: row) ?? "",
                isbn13: ImportMapping.isbn(table.value("ISBN13", in: row), table.value("ISBN", in: row)),
                pageCount: table.value("Number of Pages", in: row).flatMap { Int($0) }.flatMap { $0 > 0 ? $0 : nil },
                publishedYear: year,
                publisher: table.value("Publisher", in: row),
                format: ImportMapping.format(table.value("Binding", in: row)),
                status: status(forShelf: shelf),
                rating: ImportMapping.rating(table.value("My Rating", in: row)),
                review: ImportMapping.review(table.value("My Review", in: row)),
                tags: shelves,
                dateAdded: ImportDate.parse(table.value("Date Added", in: row), calendar: calendar),
                dateStarted: nil,
                dateFinished: ImportDate.parse(table.value("Date Read", in: row), calendar: calendar)
            )
        }
    }

    static func status(forShelf shelf: String) -> ReadingStatus {
        switch shelf {
        case "read": return .read
        case "currently-reading": return .reading
        case "to-read": return .wantToRead
        default:
            let dnfWords = ["dnf", "did-not-finish", "abandon", "gave-up"]
            return dnfWords.contains(where: { shelf.contains($0) }) ? .dnf : .wantToRead
        }
    }
}

/// Reads the CSV from StoryGraph: Manage Account → Export StoryGraph Library.
enum StoryGraphImporter {
    static let signatureColumns = ["Title", "Authors", "Read Status"]

    static func books(from table: CSVTable, calendar: Calendar = .current) -> [ImportedBook] {
        table.rows.compactMap { row in
            guard let title = table.value("Title", in: row) else { return nil }
            let status = status(for: table.value("Read Status", in: row))
            let readRange = lastReadRange(table.value("Dates Read", in: row), calendar: calendar)
            let finished = readRange.end ?? ImportDate.parse(table.value("Last Date Read", in: row), calendar: calendar)

            return ImportedBook(
                title: title,
                author: table.value("Authors", in: row) ?? "",
                isbn13: ImportMapping.isbn(table.value("ISBN/UID", in: row)),
                pageCount: nil,
                publishedYear: nil,
                publisher: nil,
                format: ImportMapping.format(table.value("Format", in: row)),
                status: status,
                rating: ImportMapping.rating(table.value("Star Rating", in: row)),
                review: ImportMapping.review(table.value("Review", in: row)),
                tags: ImportMapping.list(table.value("Tags", in: row)),
                dateAdded: ImportDate.parse(table.value("Date Added", in: row), calendar: calendar),
                dateStarted: readRange.start,
                dateFinished: finished
            )
        }
    }

    static func status(for raw: String?) -> ReadingStatus {
        switch (raw ?? "").lowercased() {
        case "read": .read
        case "currently-reading", "paused": .reading
        case "did-not-finish": .dnf
        default: .wantToRead
        }
    }

    /// "2024/01/02-2024/01/10, 2025/03/01-2025/03/09" -> the most recent read.
    static func lastReadRange(_ raw: String?, calendar: Calendar = .current) -> (start: Date?, end: Date?) {
        guard let last = raw?.split(separator: ",").last.map(String.init)?.trimmed, !last.isEmpty else {
            return (nil, nil)
        }
        let ends = last.contains("/") ? last.split(separator: "-").map(String.init) : [last]
        let start = ImportDate.parse(ends.first, calendar: calendar)
        let end = ends.count > 1 ? ImportDate.parse(ends.last, calendar: calendar) : nil
        return (start, end)
    }
}

enum ImportError: LocalizedError, Equatable {
    case emptyFile
    case unrecognizedFile

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            "This file is empty."
        case .unrecognizedFile:
            "This doesn't look like a Goodreads or StoryGraph export. Choose the .csv file you downloaded from their website."
        }
    }
}

/// What will happen when the user taps Import: new books, skipped duplicates and a few counts.
struct ImportPlan: Identifiable, Sendable {
    let id = UUID()
    let source: ImportSource
    let books: [ImportedBook]
    let alreadyInLibrary: [ImportedBook]

    func count(of status: ReadingStatus) -> Int {
        books.filter { $0.status == status }.count
    }

    var withoutISBN: Int {
        books.filter { $0.isbn13 == nil }.count
    }
}

enum LibraryImporter {
    static func plan(text: String, existingKeys: Set<String>, calendar: Calendar = .current) throws -> ImportPlan {
        guard let table = CSVParser.parseTable(text), !table.rows.isEmpty else { throw ImportError.emptyFile }

        let source: ImportSource
        let parsed: [ImportedBook]
        if table.hasColumns(GoodreadsImporter.signatureColumns) {
            source = .goodreads
            parsed = GoodreadsImporter.books(from: table, calendar: calendar)
        } else if table.hasColumns(StoryGraphImporter.signatureColumns) {
            source = .storyGraph
            parsed = StoryGraphImporter.books(from: table, calendar: calendar)
        } else {
            throw ImportError.unrecognizedFile
        }

        var seen = existingKeys
        var fresh: [ImportedBook] = []
        var duplicates: [ImportedBook] = []
        for book in parsed {
            let keys = matchKeys(title: book.title, author: book.author, isbn13: book.isbn13)
            if !seen.isDisjoint(with: keys) {
                duplicates.append(book)
            } else {
                fresh.append(book)
                seen.formUnion(keys)
            }
        }
        return ImportPlan(source: source, books: fresh, alreadyInLibrary: duplicates)
    }

    /// Keys that identify "the same book": its ISBN, and its title plus the author's last name.
    static func matchKeys(title: String, author: String, isbn13: String?) -> Set<String> {
        var keys = Set<String>()
        if let isbn13 { keys.insert("isbn:\(isbn13)") }
        let mainTitle = title.split(separator: ":").first.map(String.init) ?? title
        let shortTitle = simplified(mainTitle.split(separator: "(").first.map(String.init) ?? mainTitle)
        let firstAuthor = author.split(separator: ",").first.map(String.init) ?? author
        let lastName = simplified(firstAuthor.split(separator: " ").last.map(String.init) ?? "")
        if !shortTitle.isEmpty { keys.insert("work:\(shortTitle)|\(lastName)") }
        return keys
    }

    static func existingKeys(for books: [Book]) -> Set<String> {
        books.reduce(into: Set<String>()) { keys, book in
            keys.formUnion(matchKeys(title: book.title, author: book.author, isbn13: book.isbn13))
        }
    }

    private static func simplified(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }
}
