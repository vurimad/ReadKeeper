import Testing
@testable import ReadKeeper

struct ShelfLayoutTests {
    @Test func emptyInputGivesNoRows() {
        #expect(ShelfLayout.rows(itemWidths: [], maxWidth: 300, spacing: 2).isEmpty)
    }

    @Test func everythingFitsOnOneRow() {
        let rows = ShelfLayout.rows(itemWidths: [30, 30, 30], maxWidth: 100, spacing: 2)
        #expect(rows == [0..<3])
    }

    @Test func wrapsWhenTheRowIsFull() {
        // 30 + 2 + 30 + 2 + 30 = 94 fits in 95; the 4th book wraps.
        let rows = ShelfLayout.rows(itemWidths: [30, 30, 30, 30, 30], maxWidth: 95, spacing: 2)
        #expect(rows == [0..<3, 3..<5])
    }

    @Test func aBookWiderThanTheShelfStillGetsItsOwnRow() {
        let rows = ShelfLayout.rows(itemWidths: [20, 200, 20], maxWidth: 100, spacing: 2)
        #expect(rows == [0..<1, 1..<2, 2..<3])
    }

    @Test func everyBookAppearsExactlyOnce() {
        let widths = DemoLibrary.books.map { SpineGenerator.width(forPages: $0.pageCount) }
        let rows = ShelfLayout.rows(itemWidths: widths, maxWidth: 330, spacing: 2)
        let indices = rows.flatMap { Array($0) }
        #expect(indices == Array(0..<widths.count))
    }
}
