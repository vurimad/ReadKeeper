import Foundation

enum ShelfMetrics {
    static let shelfHeight: Double = 150
    static let spineSpacing: Double = 2
    /// Padding inside the shelf, between the wood edge and the first book.
    static let innerPadding: Double = 10
    /// Padding between the screen edge and the shelf.
    static let outerPadding: Double = 16
}

/// Splits books into shelf rows so each row fits the available width.
enum ShelfLayout {
    static func rows(itemWidths: [Double], maxWidth: Double, spacing: Double) -> [Range<Int>] {
        guard !itemWidths.isEmpty else { return [] }
        guard maxWidth > 0 else { return [0..<itemWidths.count] }

        var rows: [Range<Int>] = []
        var rowStart = 0
        var usedWidth = 0.0

        for (index, width) in itemWidths.enumerated() {
            let isFirstInRow = index == rowStart
            let needed = isFirstInRow ? width : usedWidth + spacing + width
            if needed > maxWidth && !isFirstInRow {
                rows.append(rowStart..<index)
                rowStart = index
                usedWidth = width
            } else {
                usedWidth = needed
            }
        }
        rows.append(rowStart..<itemWidths.count)
        return rows
    }
}
