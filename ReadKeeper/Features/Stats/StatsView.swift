import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @Query private var books: [Book]
    @AppStorage(ReadingGoal.storageKey) private var yearlyGoal = 0
    @State private var editingGoal = false
    @State private var sharingYear = false

    var body: some View {
        let now = Date.now
        let year = Calendar.current.component(.year, from: now)
        let finishedThisYear = ReadingGoal.booksFinished(in: year, finishDates: books.compactMap(\.dateFinished))
        let streak = StreakCalculator.summary(activityDays: ReadingActivity.activityDays(books: books), today: now)
        let week = ReadingActivity.weekSummary(books: books, now: now)
        let yearStats = YearStats.compute(books: books, year: year)

        NavigationStack {
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: 16) {
                        GoalCard(year: year, finished: finishedThisYear, goal: yearlyGoal) {
                            editingGoal = true
                        }
                        StreakCard(summary: streak)
                        WeekCard(summary: week)
                        YearCard(stats: yearStats)
                            .id("year")
                    }
                    .padding(16)
                }
                .task {
                    if let target = LaunchOptions.statsScrollTarget {
                        try? await Task.sleep(for: .milliseconds(300))
                        reader.scrollTo(target, anchor: .top)
                    }
                }
            }
            .background(WallBackground().ignoresSafeArea())
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sharingYear = true
                    } label: {
                        Label("Share My Year", systemImage: "square.and.arrow.up")
                    }
                    .disabled(yearStats.booksFinished == 0)
                }
            }
            .sheet(isPresented: $editingGoal) {
                GoalEditorSheet(goal: $yearlyGoal)
            }
            .sheet(isPresented: $sharingYear) {
                ShareCardSheet(kind: .year)
            }
        }
    }
}

/// Your year in books: monthly chart, pages, ratings, formats, tropes, longest book.
private struct YearCard: View {
    let stats: YearStats

    var body: some View {
        StatCard(title: "Your \(String(stats.year)) in Books", systemImage: "books.vertical") {
            if stats.booksFinished == 0 {
                Text("Finish a book this year to see your monthly chart, favorite tropes and more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    metric("\(stats.booksFinished)", "books")
                    Divider().frame(height: 36)
                    metric(stats.pagesFinished.formatted(), "pages")
                    Divider().frame(height: 36)
                    metric(stats.averageRating.map { String(format: "%.1f", $0) } ?? "–", "avg rating")
                }

                Chart {
                    ForEach(Array(stats.booksPerMonth.enumerated()), id: \.offset) { month, count in
                        BarMark(
                            x: .value("Month", Calendar.current.shortMonthSymbols[month]),
                            y: .value("Books", count)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(3)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 8))
                    }
                }
                .frame(height: 140)
                .padding(.top, 4)
                .accessibilityLabel("Books finished per month")

                if let month = stats.busiestMonth {
                    Text("Busiest month: \(Calendar.current.monthSymbols[month])")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !stats.formatCounts.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(BookFormat.allCases.filter { stats.formatCounts[$0] != nil }) { format in
                            ChipView(text: "\(format.title) \(stats.formatCounts[format] ?? 0)", isSelected: false, systemImage: format.systemImage)
                        }
                    }
                }

                if !stats.topTropes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Favorite tropes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(stats.topTropes, id: \.self) { ChipView(text: $0) }
                        }
                    }
                }

                if let title = stats.longestBookTitle, let pages = stats.longestBookPages {
                    Label("Longest: \(title) (\(pages) pages)", systemImage: "ruler")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }
}

private struct GoalCard: View {
    let year: Int
    let finished: Int
    let goal: Int
    let onEdit: () -> Void

    var body: some View {
        StatCard(title: "\(year) Reading Goal", systemImage: "target") {
            if goal > 0 {
                HStack(spacing: 20) {
                    GoalRing(fraction: Double(finished) / Double(goal))
                        .frame(width: 96, height: 96)
                        .overlay {
                            VStack(spacing: 0) {
                                Text("\(finished)")
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .monospacedDigit()
                                Text("of \(goal)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ReadingGoal.paceText(finished: finished, goal: goal, date: .now))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        Text("\(max(goal - finished, 0)) to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Change Goal", action: onEdit)
                            .font(.subheadline)
                            .tint(Theme.accent)
                    }
                }
            } else {
                Text("You've finished \(finished) \(finished == 1 ? "book" : "books") this year.")
                    .foregroundStyle(.secondary)
                Button("Set a Reading Goal", action: onEdit)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
            }
        }
    }
}

private struct GoalRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ink.opacity(0.1), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityElement()
        .accessibilityLabel("Goal progress")
        .accessibilityValue("\(Int((min(fraction, 1) * 100).rounded())) percent")
    }
}

private struct StreakCard: View {
    let summary: StreakSummary

    var body: some View {
        StatCard(title: "Reading Streak", systemImage: "flame") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(summary.current)")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text(summary.current == 1 ? "day" : "days")
                    .foregroundStyle(.secondary)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var message: String {
        if summary.current == 0 {
            return "Log some reading to start a streak. One rest day a week won't break it."
        }
        if summary.readToday {
            return summary.restDayUsedThisWeek
                ? "You read today. This week's rest day is used."
                : "You read today. You still have a free rest day this week."
        }
        return summary.restDayUsedThisWeek
            ? "Read today to keep your streak. This week's rest day is used."
            : "Haven't read yet today? Today can be your rest day."
    }
}

private struct WeekCard: View {
    let summary: WeekSummary

    var body: some View {
        StatCard(title: "This Week", systemImage: "calendar") {
            HStack {
                metric(value: "\(summary.pages)", label: "pages")
                Divider().frame(height: 36)
                metric(value: ProgressMath.durationText(minutes: Double(summary.listeningMinutes)), label: "listening")
                Divider().frame(height: 36)
                metric(value: "\(summary.daysRead)", label: summary.daysRead == 1 ? "day read" : "days read")
            }
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsView()
        .modelContainer(Persistence.previewContainer())
}
