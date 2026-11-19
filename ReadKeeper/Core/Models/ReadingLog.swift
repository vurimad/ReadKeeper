import Foundation
import SwiftData

/// One reading update: on `date`, the reader moved from `startValue` to `endValue`.
@Model
final class ReadingLog {
    var id: UUID = UUID()
    /// The day the reading happened (can be in the past when backfilling).
    var date: Date = Date()
    var startValue: Double = 0
    var endValue: Double = 0
    var unitRaw: String = ProgressUnit.pages.rawValue
    var playbackSpeed: Double = 1
    var createdAt: Date = Date()
    var book: Book?

    init(date: Date, startValue: Double, endValue: Double, unit: ProgressUnit, playbackSpeed: Double = 1, createdAt: Date = .now) {
        self.date = date
        self.startValue = startValue
        self.endValue = endValue
        self.unitRaw = unit.rawValue
        self.playbackSpeed = playbackSpeed
        self.createdAt = createdAt
    }

    var unit: ProgressUnit {
        ProgressUnit(rawValue: unitRaw) ?? .pages
    }

    var amount: Double {
        endValue - startValue
    }

    /// "+24 pages", "+5%", "+45m"
    var amountText: String {
        ProgressMath.deltaText(amount, unit: unit)
    }
}

/// A favorite passage saved from a book.
@Model
final class Quote {
    var id: UUID = UUID()
    var text: String = ""
    var page: Int?
    var createdAt: Date = Date()
    var book: Book?

    init(text: String, page: Int? = nil, createdAt: Date = .now) {
        self.text = text
        self.page = page
        self.createdAt = createdAt
    }
}
