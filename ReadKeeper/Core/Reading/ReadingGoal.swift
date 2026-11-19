import Foundation

/// The yearly "read N books" goal.
enum ReadingGoal {
    /// UserDefaults key (0 means no goal set).
    static let storageKey = "yearlyBookGoal"
    static let range = 1...365

    static func booksFinished(in year: Int, finishDates: [Date], calendar: Calendar = .current) -> Int {
        finishDates.filter { calendar.component(.year, from: $0) == year }.count
    }

    /// How many books you'd have finished by `date` reading at an even pace.
    static func expectedByNow(goal: Int, date: Date, calendar: Calendar = .current) -> Double {
        guard goal > 0,
              let yearInterval = calendar.dateInterval(of: .year, for: date) else { return 0 }
        let elapsed = date.timeIntervalSince(yearInterval.start) / yearInterval.duration
        return Double(goal) * min(max(elapsed, 0), 1)
    }

    /// "2 books ahead of schedule", "On track", "1 book behind schedule", "Goal reached!"
    static func paceText(finished: Int, goal: Int, date: Date, calendar: Calendar = .current) -> String {
        guard goal > 0 else { return "" }
        if finished >= goal { return "Goal reached!" }
        let difference = Double(finished) - expectedByNow(goal: goal, date: date, calendar: calendar)
        let books = Int(abs(difference).rounded())
        if books == 0 { return "On track" }
        let noun = books == 1 ? "book" : "books"
        return difference > 0 ? "\(books) \(noun) ahead of schedule" : "\(books) \(noun) behind schedule"
    }
}
