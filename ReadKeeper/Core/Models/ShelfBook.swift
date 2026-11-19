import Foundation

/// Minimal book value used by the shelf. Replaced by the persisted Book model in M1.
struct ShelfBook: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var author: String
    var pageCount: Int?

    init(id: UUID = UUID(), title: String, author: String, pageCount: Int? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.pageCount = pageCount
    }

    /// Thin spines only have room for the last-name initial.
    func spineInitials(forWidth width: Double) -> String {
        width < 26 ? String(authorInitials.suffix(1)) : authorInitials
    }

    /// "Jane Austen" -> "JA"
    var authorInitials: String {
        author
            .split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}
