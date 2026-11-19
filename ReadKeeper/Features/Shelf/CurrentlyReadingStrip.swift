import SwiftUI

/// "Currently reading" cards above the shelf, with a one-tap Log button.
struct CurrentlyReadingStrip: View {
    let books: [Book]
    let onLog: (Book) -> Void
    let onOpen: (Book) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Currently reading")
                .font(.headline)
                .fontDesign(.serif)
                .foregroundStyle(Theme.ink)

            if let only = books.first, books.count == 1 {
                CurrentlyReadingCard(book: only, onLog: { onLog(only) })
                    .onTapGesture { onOpen(only) }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(books) { book in
                            CurrentlyReadingCard(book: book, onLog: { onLog(book) })
                                .frame(width: 300)
                                .onTapGesture { onOpen(book) }
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct CurrentlyReadingCard: View {
    let book: Book
    let onLog: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            CoverImageView(book: book)
                .frame(width: 48, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Theme.ink)
                Text(book.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let fraction = book.progressFraction {
                    ReadingProgressBar(fraction: fraction, height: 6)
                }
            }

            Spacer(minLength: 4)

            Button(action: onLog) {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 40, height: 40)
                    .background(Theme.accent, in: Circle())
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Log progress for \(book.title)")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
    }
}
