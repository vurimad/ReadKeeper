import Testing
@testable import ReadKeeper

struct SpineGeneratorTests {
    @Test func sameBookAlwaysGetsTheSameSpine() {
        let first = SpineGenerator.style(title: "Emma", author: "Jane Austen", pageCount: 474)
        let second = SpineGenerator.style(title: "  emma ", author: "JANE AUSTEN", pageCount: 474)
        #expect(first == second)
    }

    @Test func differentBooksUsuallyLookDifferent() {
        let styles = DemoLibrary.books.map {
            SpineGenerator.style(title: $0.title, author: $0.author, pageCount: $0.pageCount)
        }
        let distinctColors = Set(styles.map(\.base))
        #expect(distinctColors.count >= 8)

        // No single color should dominate the demo shelf.
        let counts = Dictionary(grouping: styles, by: \.base).mapValues(\.count)
        #expect((counts.values.max() ?? 0) <= 5)
    }

    static let widthCases: [(Int?, Double)] = [
        (nil, SpineGenerator.defaultWidth),
        (0, SpineGenerator.defaultWidth),
        (50, SpineGenerator.minWidth),
        (420, 30.0),
        (5000, SpineGenerator.maxWidth),
    ]

    @Test(arguments: widthCases)
    func widthFollowsPageCountWithinLimits(pages: Int?, expected: Double) {
        #expect(SpineGenerator.width(forPages: pages) == expected)
    }

    @Test func heightStaysInRange() {
        for book in DemoLibrary.books {
            let style = SpineGenerator.style(title: book.title, author: book.author, pageCount: book.pageCount)
            #expect(style.heightFactor >= 0.80 && style.heightFactor <= 0.98)
        }
    }

    @Test func spineTextIsReadableOnEveryPaletteColor() {
        for base in SpineGenerator.palette {
            let text = SpineGenerator.textColor(on: base)
            #expect(base.contrastRatio(with: text) >= 3.0, "Low contrast on \(base)")
        }
    }

    @Test func stableHashIsStable() {
        // FNV-1a reference value for an empty string.
        #expect(StableHash.fnv1a("") == 0xcbf2_9ce4_8422_2325)
        #expect(StableHash.fnv1a("ReadKeeper") == StableHash.fnv1a("ReadKeeper"))
    }

    @Test func authorInitials() {
        #expect(ShelfBook(title: "x", author: "Jane Austen").authorInitials == "JA")
        #expect(ShelfBook(title: "x", author: "Homer").authorInitials == "H")
        #expect(ShelfBook(title: "x", author: "Louisa May Alcott").authorInitials == "LM")
    }
}
