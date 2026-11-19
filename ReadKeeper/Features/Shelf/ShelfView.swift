import SwiftUI

struct ShelfView: View {
    @State private var books: [ShelfBook] = LaunchOptions.showsDemoShelf ? DemoLibrary.books : []

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        if books.isEmpty {
                            EmptyShelfCard()
                            ForEach(0..<3, id: \.self) { _ in
                                ShelfRowView(books: [])
                            }
                        } else {
                            ForEach(rows(forWidth: proxy.size.width), id: \.self) { range in
                                ShelfRowView(books: Array(books[range]))
                            }
                        }
                    }
                    .padding(.horizontal, ShelfMetrics.outerPadding)
                    .padding(.vertical, 16)
                }
            }
            .background(WallBackground().ignoresSafeArea())
            .navigationTitle("My Shelf")
        }
    }

    private func rows(forWidth width: Double) -> [Range<Int>] {
        let usableWidth = width - 2 * (ShelfMetrics.outerPadding + ShelfMetrics.innerPadding)
        let widths = books.map { SpineGenerator.width(forPages: $0.pageCount) }
        return ShelfLayout.rows(itemWidths: widths, maxWidth: usableWidth, spacing: ShelfMetrics.spineSpacing)
    }
}

/// One shelf: books standing on a wooden board.
struct ShelfRowView: View {
    let books: [ShelfBook]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: ShelfMetrics.spineSpacing) {
                ForEach(books) { book in
                    BookSpineView(book: book, shelfHeight: ShelfMetrics.shelfHeight)
                }
                Spacer(minLength: 0)
            }
            .frame(height: ShelfMetrics.shelfHeight, alignment: .bottom)
            .padding(.horizontal, ShelfMetrics.innerPadding)

            ShelfPlankView()
        }
    }
}

struct EmptyShelfCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Theme.accent)
            Text("Your shelf is waiting")
                .font(.title3.weight(.semibold))
                .fontDesign(.serif)
                .foregroundStyle(Theme.ink)
            Text("Add the books you're reading, have read, or want to read.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink.opacity(0.75))
            Button("Add your first book") {}
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(true)
            Text("Adding books arrives in the next build.")
                .font(.caption)
                .foregroundStyle(Theme.ink.opacity(0.55))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

#Preview("Empty") {
    ShelfView()
}
