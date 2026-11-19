import Foundation
import Testing
@testable import ReadKeeper

struct ShelfReorderTests {
    let a = UUID(), b = UUID(), c = UUID(), d = UUID()

    @Test func movesBeforeTarget() {
        #expect(ShelfOrdering.reordered([a, b, c, d], moving: d, before: b) == [a, d, b, c])
        #expect(ShelfOrdering.reordered([a, b, c, d], moving: a, before: d) == [b, c, a, d])
    }

    @Test func nilTargetMovesToTheEnd() {
        #expect(ShelfOrdering.reordered([a, b, c, d], moving: a, before: nil) == [b, c, d, a])
    }

    @Test func noOpCases() {
        #expect(ShelfOrdering.reordered([a, b, c], moving: b, before: b) == [a, b, c])
        #expect(ShelfOrdering.reordered([a, b, c], moving: d, before: a) == [a, b, c])
    }
}

struct ShelfSortKeyTests {
    @Test func titlesIgnoreLeadingArticles() {
        #expect(ShelfOrdering.titleKey("The Great Gatsby") == "great gatsby")
        #expect(ShelfOrdering.titleKey("A Room with a View") == "room with a view")
        #expect(ShelfOrdering.titleKey("An Ember in the Ashes") == "ember in the ashes")
        #expect(ShelfOrdering.titleKey("Anna Karenina") == "anna karenina")
    }

    @Test func authorsSortByLastNameIgnoringAccents() {
        #expect(ShelfOrdering.authorKey("Charlotte Brontë") == "bronte")
        #expect(ShelfOrdering.authorKey("Homer") == "homer")
    }

    @Test func hslForPrimaryAndNeutralColors() {
        let red = RGB(red: 1, green: 0, blue: 0).hsl
        #expect(red.hue == 0 && red.saturation == 1 && red.lightness == 0.5)
        #expect(abs(RGB(red: 0, green: 1, blue: 0).hsl.hue - 1.0 / 3) < 0.0001)
        #expect(abs(RGB(red: 0, green: 0, blue: 1).hsl.hue - 2.0 / 3) < 0.0001)
        #expect(RGB(hex: 0x808080).hsl.saturation == 0)
    }

    @Test func colorfulBooksComeBeforeNeutralOnes() {
        let red = ShelfOrdering.colorKey(RGB(hex: 0x7A2E2E))
        let navy = ShelfOrdering.colorKey(RGB(hex: 0x1F3A5A))
        let charcoal = ShelfOrdering.colorKey(RGB(hex: 0x2B2B2B))
        let cream = ShelfOrdering.colorKey(RGB(hex: 0xE6D7C3))
        #expect(red < navy)
        #expect(navy < charcoal)
        // Neutrals go light to dark.
        #expect(cream < charcoal)
    }

    @Test func thinSpinesShowOnlyTheLastNameInitial() {
        let book = ShelfBook(title: "Emma", author: "Jane Austen")
        #expect(book.spineInitials(forWidth: 20) == "A")
        #expect(book.spineInitials(forWidth: 30) == "JA")
    }
}

struct ShelfArrangementTests {
    private func makeBooks() -> [Book] {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let gatsby = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", dateAdded: now)
        let emma = Book(title: "Emma", author: "Jane Austen", dateAdded: now.addingTimeInterval(-100))
        let dracula = Book(title: "Dracula", author: "Bram Stoker", dateAdded: now.addingTimeInterval(-200))
        let dnf = Book(title: "Abandoned", author: "Nobody", dateAdded: now.addingTimeInterval(100))
        dnf.setStatus(.dnf, now: now)
        return [gatsby, emma, dracula, dnf]
    }

    @Test func dnfBooksNeverAppearOnTheShelf() {
        for arrangement in ShelfArrangement.allCases {
            let titles = ShelfOrdering.arranged(makeBooks(), by: arrangement).map(\.title)
            #expect(!titles.contains("Abandoned"), "\(arrangement)")
            #expect(titles.count == 3)
        }
    }

    @Test func byTitleAuthorAndRecent() {
        let books = makeBooks()
        #expect(ShelfOrdering.arranged(books, by: .title).map(\.title) == ["Dracula", "Emma", "The Great Gatsby"])
        #expect(ShelfOrdering.arranged(books, by: .author).map(\.title) == ["Emma", "The Great Gatsby", "Dracula"])
        #expect(ShelfOrdering.arranged(books, by: .recentlyAdded).map(\.title) == ["The Great Gatsby", "Emma", "Dracula"])
    }

    @Test func myOrderUsesPositionsAndPutsNewBooksLast() {
        let books = makeBooks()
        books[2].shelfOrder = 1 // Dracula first
        books[0].shelfOrder = 2 // Gatsby second
        // Emma was never placed, so she goes after the placed books.
        #expect(ShelfOrdering.arranged(books, by: .custom).map(\.title) == ["Dracula", "The Great Gatsby", "Emma"])
    }
}

struct TiltMathTests {
    @Test func normalizesAngles() {
        #expect(TiltMath.normalize(0.25, range: 0.5) == 0.5)
        #expect(TiltMath.normalize(2, range: 0.5) == 1)
        #expect(TiltMath.normalize(-2, range: 0.5) == -1)
        #expect(TiltMath.normalize(1, range: 0) == 0)
    }

    @Test func smoothsTowardTheTarget() {
        let next = TiltMath.smooth(current: .zero, target: CGSize(width: 1, height: -1), factor: 0.5)
        #expect(next == CGSize(width: 0.5, height: -0.5))
    }
}
