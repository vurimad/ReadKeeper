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
                                .frame(width: 318)
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

    private let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            CoverImageView(book: book)
                .frame(width: 58, height: 87)
                .shadow(color: .black.opacity(0.22), radius: 5, x: 2, y: 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .fontDesign(.serif)
                    .lineLimit(1)
                    .foregroundStyle(Theme.ink)
                Text(book.displayAuthor)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline) {
                    Text(book.progressText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                    Spacer(minLength: 6)
                    if let fraction = book.progressFraction {
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 2)

                ReadingProgressBar(fraction: book.progressFraction ?? 0, height: 7)

                if let lastRead = ReadingActivity.lastReadText(lastRead: book.sortedLogs.first?.date, now: .now) {
                    Text(lastRead)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onLog) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Theme.accent, in: Circle())
                    .shadow(color: Theme.accent.opacity(0.35), radius: 6, y: 3)
            }
            .accessibilityLabel("Log progress for \(book.title)")
        }
        .padding(14)
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
