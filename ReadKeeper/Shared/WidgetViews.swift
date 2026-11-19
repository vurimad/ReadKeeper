import SwiftUI
import WidgetKit

// Widget designs, shared by the widget extension and the app's widget gallery (for screenshots).
// They take the family as a parameter because only real widgets have it in their environment.

/// Cover for widgets: the saved thumbnail, or a generated cover in the book's spine colors.
struct WidgetCover: View {
    let item: WidgetSnapshot.ReadingItem

    var body: some View {
        Group {
            if let data = item.coverThumbnail, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                let style = SpineGenerator.style(title: item.title, author: item.author, pageCount: nil)
                GeometryReader { proxy in
                    ZStack {
                        LinearGradient(
                            colors: [Color(style.base.mixed(with: .white, amount: 0.1)), Color(style.base.mixed(with: .black, amount: 0.2))],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(Color(style.accent), lineWidth: 1)
                            .padding(3)
                        Text(item.title)
                            .font(.system(size: Self.fontSize(for: item.title, width: proxy.size.width - 10), weight: .semibold, design: .serif))
                            .foregroundStyle(Color(style.text))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(5)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }

    /// Same rule as the app's generated covers: the longest word fits on one line.
    nonisolated static func fontSize(for title: String, width: Double) -> Double {
        let longestWord = title.split(whereSeparator: { $0 == " " || $0 == "-" }).map(\.count).max() ?? 1
        return max(4, min(11, width / (Double(max(longestWord, 1)) * 0.6)))
    }
}

/// Thin rounded progress bar that works in widgets (no GeometryReader animation).
struct WidgetProgressBar: View {
    let fraction: Double
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.12))
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(height, proxy.size.width * CGFloat(min(max(fraction, 0), 1))))
                    .opacity(fraction > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Currently Reading widget

struct CurrentlyReadingWidgetContent: View {
    let family: WidgetFamily
    let snapshot: WidgetSnapshot
    let date: Date

    var body: some View {
        switch family {
        case .systemMedium:
            medium
        case .accessoryRectangular:
            rectangular
        case .accessoryCircular:
            circular
        default:
            small
        }
    }

    private var first: WidgetSnapshot.ReadingItem? { snapshot.reading.first }

    @ViewBuilder
    private var small: some View {
        if let item = first {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    WidgetCover(item: item)
                        .frame(width: 44, height: 66)
                    Spacer(minLength: 4)
                    if let fraction = item.fraction {
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 6)
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                WidgetProgressBar(fraction: item.fraction ?? 0)
                    .padding(.top, 6)
                Text(item.progressText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                    .lineLimit(1)
                    .padding(.top, 4)
            }
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private var medium: some View {
        if snapshot.reading.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Currently reading")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if snapshot.streakDays > 0 {
                        Label("\(snapshot.streakDays)", systemImage: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                ForEach(snapshot.reading.prefix(2)) { item in
                    HStack(spacing: 10) {
                        WidgetCover(item: item)
                            .frame(width: 30, height: 45)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                if let fraction = item.fraction {
                                    Text("\(Int((fraction * 100).rounded()))%")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                        .monospacedDigit()
                                }
                            }
                            WidgetProgressBar(fraction: item.fraction ?? 0, height: 4)
                            Text(item.progressText)
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.ink.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if let item = first {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                ProgressView(value: item.fraction ?? 0)
                Text(item.progressText)
                    .font(.caption2)
                    .lineLimit(1)
            }
        } else {
            Text("No book in progress")
                .font(.caption)
        }
    }

    private var circular: some View {
        Gauge(value: first?.fraction ?? 0) {
            Image(systemName: "book")
        } currentValueLabel: {
            if let fraction = first?.fraction {
                Text("\(Int((fraction * 100).rounded()))")
            } else {
                Image(systemName: "book")
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "books.vertical")
                .font(.title2)
                .foregroundStyle(Theme.accent)
            Spacer(minLength: 0)
            Text("Nothing on the go")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("Start a book in ReadKeeper.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Streak & Goal widget

struct StreakGoalWidgetContent: View {
    let family: WidgetFamily
    let snapshot: WidgetSnapshot
    let date: Date

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryInline:
            Text(inlineText)
        case .accessoryRectangular:
            rectangular
        default:
            small
        }
    }

    private var readToday: Bool { snapshot.hasReadToday(at: date) }

    private var inlineText: String {
        var parts: [String] = []
        if snapshot.streakDays > 0 { parts.append("🔥 \(snapshot.streakDays)-day streak") }
        if snapshot.goal > 0 { parts.append("\(snapshot.finishedThisYear)/\(snapshot.goal) books") }
        return parts.isEmpty ? "ReadKeeper" : parts.joined(separator: " · ")
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.accent)
                Text("\(snapshot.streakDays)")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            Text(snapshot.streakDays == 1 ? "day streak" : "day streak")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
            Text(readToday ? "Read today ✓" : "Read today to keep it")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(readToday ? Theme.accent : Theme.ink.opacity(0.55))
                .padding(.top, 2)

            Spacer(minLength: 6)

            if let fraction = snapshot.goalFraction {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(Theme.ink.opacity(0.12), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(snapshot.finishedThisYear) of \(snapshot.goal)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("books in \(String(snapshot.year))")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                }
            } else {
                Text("\(snapshot.finishedThisYear) books in \(String(snapshot.year))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circular: some View {
        Gauge(value: snapshot.goalFraction ?? 0) {
            Text("Goal")
        } currentValueLabel: {
            Text("\(snapshot.finishedThisYear)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("\(snapshot.streakDays)-day streak", systemImage: "flame.fill")
                .font(.headline)
            if snapshot.goal > 0 {
                Text("\(snapshot.finishedThisYear) of \(snapshot.goal) books this year")
                    .font(.caption)
            }
            Text(readToday ? "Read today ✓" : "Read today to keep it")
                .font(.caption2)
        }
    }
}
