import SwiftData
import SwiftUI

struct StatsView: View {
    @Query private var books: [Book]
    @AppStorage(ReadingGoal.storageKey) private var yearlyGoal = 0
    @State private var editingGoal = false

    var body: some View {
        let now = Date.now
        let year = Calendar.current.component(.year, from: now)
        let finishedThisYear = ReadingGoal.booksFinished(in: year, finishDates: books.compactMap(\.dateFinished))
        let streak = StreakCalculator.summary(activityDays: ReadingActivity.activityDays(books: books), today: now)
        let week = ReadingActivity.weekSummary(books: books, now: now)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GoalCard(year: year, finished: finishedThisYear, goal: yearlyGoal) {
                        editingGoal = true
                    }
                    StreakCard(summary: streak)
                    WeekCard(summary: week)
                    Text("More stats, charts and your Year in Books arrive in a later update.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .background(WallBackground().ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(isPresented: $editingGoal) {
                GoalEditorSheet(goal: $yearlyGoal)
            }
        }
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
