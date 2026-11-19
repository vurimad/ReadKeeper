import SwiftUI

/// "Currently reading" cards above the shelf, with a one-tap Log button.
struct CurrentlyReadingStrip: View {
    let books: [Book]
    let streakDays: Int
    let namespace: Namespace.ID
    let onLog: (Book) -> Void
    let onOpen: (Book) -> Void

    static func sourceID(for book: Book) -> String { "card-\(book.id.uuidString)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Currently reading")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if streakDays > 0 {
                    Label("\(streakDays)-day streak", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                        .accessibilityLabel("\(streakDays) day reading streak")
                }
            }

            if let only = books.first, books.count == 1 {
                card(for: only)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(books) { book in
                            card(for: book)
                                .frame(width: 330)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    private func card(for book: Book) -> some View {
        CurrentlyReadingCard(book: book, onLog: { onLog(book) })
            .matchedTransitionSource(id: Self.sourceID(for: book), in: namespace)
            .onTapGesture { onOpen(book) }
    }
}

private struct CurrentlyReadingCard: View {
    let book: Book
    let onLog: () -> Void

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CoverImageView(book: book)
                .frame(width: 76, height: 114)
                .shadow(color: .black.opacity(0.24), radius: 6, x: 2, y: 4)

            VStack(alignment: .leading, spacing: 0) {
                // Title block
                Text(book.title)
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .lineLimit(2)
                    .foregroundStyle(Theme.ink)
                Text(book.displayAuthor)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                Spacer(minLength: 14)

                // Progress block
                HStack(alignment: .firstTextBaseline) {
                    Text(book.progressText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                    Spacer(minLength: 6)
                    if let fraction = book.progressFraction {
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                    }
                }
                ReadingProgressBar(fraction: book.progressFraction ?? 0, height: 7)
                    .padding(.top, 6)

                // Action row
                HStack(alignment: .center) {
                    if let lastRead = ReadingActivity.lastReadText(lastRead: book.sortedLogs.first?.date, now: .now) {
                        Text(lastRead)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button(action: onLog) {
                        Label("Log", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.accent, in: Capsule())
                            .shadow(color: Theme.accent.opacity(0.3), radius: 5, y: 2)
                    }
                    .accessibilityLabel("Log progress for \(book.title)")
                }
                .padding(.top, 12)
            }
            .frame(minHeight: 114)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.card, Theme.cardGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: shape
        )
        .overlay(shape.strokeBorder(Theme.accent.opacity(0.22), lineWidth: 1))
        .shadow(color: Theme.accent.opacity(0.16), radius: 14, y: 6)
        .contentShape(shape)
        .accessibilityElement(children: .contain)
    }
}
