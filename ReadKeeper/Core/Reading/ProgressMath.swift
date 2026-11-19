import Foundation

/// Progress calculations and formatting for pages, percent and audiobook time.
enum ProgressMath {
    /// Slowest and fastest audiobook speeds offered.
    static let playbackSpeeds: [Double] = [0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3]

    static func total(unit: ProgressUnit, pageCount: Int?, totalMinutes: Int?) -> Double? {
        switch unit {
        case .pages: pageCount.flatMap { $0 > 0 ? Double($0) : nil }
        case .percent: 100
        case .minutes: totalMinutes.flatMap { $0 > 0 ? Double($0) : nil }
        }
    }

    static func fraction(value: Double, unit: ProgressUnit, pageCount: Int?, totalMinutes: Int?) -> Double? {
        guard let total = total(unit: unit, pageCount: pageCount, totalMinutes: totalMinutes) else { return nil }
        return min(max(value / total, 0), 1)
    }

    /// Keeps a position between 0 and the book's total (when known).
    static func clamp(_ value: Double, unit: ProgressUnit, pageCount: Int?, totalMinutes: Int?) -> Double {
        let lowerBounded = max(0, value)
        guard let total = total(unit: unit, pageCount: pageCount, totalMinutes: totalMinutes) else { return lowerBounded }
        return min(lowerBounded, total)
    }

    /// Real time spent listening: 60 book-minutes at 1.5x takes 40 minutes.
    static func listeningMinutes(bookMinutes: Double, speed: Double) -> Double {
        bookMinutes / max(speed, 0.5)
    }

    /// Pages read for a progress change, converting percent when the page count is known.
    static func pagesRead(amount: Double, unit: ProgressUnit, pageCount: Int?) -> Double {
        switch unit {
        case .pages: max(0, amount)
        case .percent: pageCount.map { max(0, amount) / 100 * Double($0) } ?? 0
        case .minutes: 0
        }
    }

    // MARK: Formatting

    static func durationText(minutes: Double) -> String {
        let total = Int(minutes.rounded())
        let hours = total / 60
        let mins = total % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }

    static func positionText(value: Double, unit: ProgressUnit, pageCount: Int?, totalMinutes: Int?) -> String {
        switch unit {
        case .pages:
            let page = Int(value.rounded())
            if let pageCount, pageCount > 0 { return "p. \(page) of \(pageCount)" }
            return "p. \(page)"
        case .percent:
            return "\(Int(value.rounded()))%"
        case .minutes:
            let position = durationText(minutes: value)
            if let totalMinutes, totalMinutes > 0 { return "\(position) of \(durationText(minutes: Double(totalMinutes)))" }
            return position
        }
    }

    static func deltaText(_ amount: Double, unit: ProgressUnit) -> String {
        let sign = amount < 0 ? "−" : "+"
        let magnitude = abs(amount)
        switch unit {
        case .pages:
            let pages = Int(magnitude.rounded())
            return "\(sign)\(pages) \(pages == 1 ? "page" : "pages")"
        case .percent:
            return "\(sign)\(Int(magnitude.rounded()))%"
        case .minutes:
            return "\(sign)\(durationText(minutes: magnitude))"
        }
    }

    static func speedText(_ speed: Double) -> String {
        let formatted = speed.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(speed))
            : String(format: "%g", speed)
        return "\(formatted)×"
    }
}
