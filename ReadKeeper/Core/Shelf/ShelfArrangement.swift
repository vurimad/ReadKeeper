import Foundation

/// How books are arranged on the shelf.
enum ShelfArrangement: String, CaseIterable, Identifiable, Sendable {
    case readingFirst
    case color
    case author
    case title
    case recentlyAdded
    case custom

    /// UserDefaults key. Also settable with the launch argument `-shelfArrangement color`.
    static let storageKey = "shelfArrangement"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .readingFirst: "Reading First"
        case .color: "By Color"
        case .author: "By Author"
        case .title: "By Title"
        case .recentlyAdded: "Recently Added"
        case .custom: "My Order"
        }
    }

    var systemImage: String {
        switch self {
        case .readingFirst: "book"
        case .color: "paintpalette"
        case .author: "person"
        case .title: "textformat"
        case .recentlyAdded: "clock"
        case .custom: "hand.draw"
        }
    }
}

extension ShelfOrdering {
    /// Books on the shelf (DNF excluded) in the chosen arrangement.
    static func arranged(_ books: [Book], by arrangement: ShelfArrangement) -> [Book] {
        let visible = books.filter { $0.status != .dnf }
        switch arrangement {
        case .readingFirst:
            return sorted(books)
        case .color:
            return visible.sorted { colorKey($0) < colorKey($1) }
        case .author:
            return visible.sorted {
                (authorKey($0.author), titleKey($0.title)) < (authorKey($1.author), titleKey($1.title))
            }
        case .title:
            return visible.sorted { titleKey($0.title) < titleKey($1.title) }
        case .recentlyAdded:
            return visible.sorted { $0.dateAdded > $1.dateAdded }
        case .custom:
            return visible.sorted { customKey($0) < customKey($1) }
        }
    }

    /// Moves `moving` so it sits right before `target` (or at the end when `target` is nil).
    static func reordered(_ ids: [UUID], moving: UUID, before target: UUID?) -> [UUID] {
        guard ids.contains(moving), moving != target else { return ids }
        var result = ids.filter { $0 != moving }
        if let target, let index = result.firstIndex(of: target) {
            result.insert(moving, at: index)
        } else {
            result.append(moving)
        }
        return result
    }

    // MARK: Sort keys

    /// Rainbow order; greys, blacks and creams (low saturation) go last, light to dark.
    static func colorKey(_ book: Book) -> (Double, Double, Double) {
        let base = SpineGenerator.style(title: book.title, author: book.author, pageCount: book.pageCount).base
        return colorKey(base)
    }

    static func colorKey(_ color: RGB) -> (Double, Double, Double) {
        let (hue, saturation, lightness) = color.hsl
        let isNeutral = saturation < 0.18
        return (isNeutral ? 1 : 0, isNeutral ? -lightness : hue, lightness)
    }

    /// Sort by last name, ignoring accents and case: "Charlotte Brontë" -> "bronte".
    static func authorKey(_ author: String) -> String {
        let lastName = author.split(separator: " ").last.map(String.init) ?? author
        return lastName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Ignores leading articles: "The Great Gatsby" sorts under G.
    static func titleKey(_ title: String) -> String {
        let lowered = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).trimmed
        for article in ["the ", "a ", "an "] where lowered.hasPrefix(article) {
            return String(lowered.dropFirst(article.count))
        }
        return lowered
    }

    /// Placed books first by position; books never placed go after, oldest first.
    private static func customKey(_ book: Book) -> (Int, Double, Double) {
        (book.shelfOrder == 0 ? 1 : 0, book.shelfOrder, book.dateAdded.timeIntervalSince1970)
    }
}
