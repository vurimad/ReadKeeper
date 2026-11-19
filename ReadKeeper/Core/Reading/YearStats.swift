import Foundation

/// A year of reading, computed from finished books.
struct YearStats: Equatable, Sendable {
    var year: Int
    var booksFinished: Int
    var pagesFinished: Int
    /// 12 entries, January first.
    var booksPerMonth: [Int]
    var averageRating: Double?
    var formatCounts: [BookFormat: Int]
    var topTropes: [String]
    var longestBookTitle: String?
    var longestBookPages: Int?
    var fiveStarCount: Int

    var busiestMonth: Int? {
        guard let peak = booksPerMonth.max(), peak > 0 else { return nil }
        return booksPerMonth.firstIndex(of: peak)
    }

    static func compute(books: [Book], year: Int, calendar: Calendar = .current) -> YearStats {
        let finished = books.filter { book in
            book.status == .read && book.dateFinished.map { calendar.component(.year, from: $0) == year } == true
        }

        var perMonth = Array(repeating: 0, count: 12)
        for book in finished {
            if let date = book.dateFinished {
                perMonth[calendar.component(.month, from: date) - 1] += 1
            }
        }

        let ratings = finished.compactMap(\.rating)
        let average = ratings.isEmpty ? nil : (ratings.reduce(0, +) / Double(ratings.count) * 10).rounded() / 10

        var formats: [BookFormat: Int] = [:]
        for book in finished { formats[book.format, default: 0] += 1 }

        var tropeCounts: [String: Int] = [:]
        for trope in finished.flatMap(\.tropes) { tropeCounts[trope, default: 0] += 1 }
        let topTropes = tropeCounts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(3)
            .map(\.key)

        let longest = finished.filter { $0.pageCount != nil }.max { ($0.pageCount ?? 0) < ($1.pageCount ?? 0) }

        return YearStats(
            year: year,
            booksFinished: finished.count,
            pagesFinished: finished.compactMap(\.pageCount).reduce(0, +),
            booksPerMonth: perMonth,
            averageRating: average,
            formatCounts: formats,
            topTropes: topTropes,
            longestBookTitle: longest?.title,
            longestBookPages: longest?.pageCount,
            fiveStarCount: ratings.filter { $0 >= 5 }.count
        )
    }
}
