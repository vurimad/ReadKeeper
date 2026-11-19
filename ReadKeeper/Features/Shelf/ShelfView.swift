import SwiftData
import SwiftUI

struct ShelfView: View {
    @Query private var books: [Book]

    @State private var showingAdd = LaunchOptions.opensAddSheet
    @State private var selectedBook: Book?

    var body: some View {
        let shelfBooks = ShelfOrdering.sorted(books)

        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        if shelfBooks.isEmpty {
                            EmptyShelfCard { showingAdd = true }
                            ForEach(0..<3, id: \.self) { _ in
                                ShelfRowView(books: [], onSelect: { _ in })
                            }
                        } else {
                            ForEach(rows(for: shelfBooks, width: proxy.size.width), id: \.self) { range in
                                ShelfRowView(books: shelfBooks[range].map(\.shelfBook)) { tapped in
                                    selectedBook = shelfBooks.first { $0.id == tapped.id }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ShelfMetrics.outerPadding)
                    .padding(.vertical, 16)
                }
            }
            .background(WallBackground().ignoresSafeArea())
            .navigationTitle("My Shelf")
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddBookView()
            }
        }
    }

    private func rows(for books: [Book], width: Double) -> [Range<Int>] {
        let usableWidth = width - 2 * (ShelfMetrics.outerPadding + ShelfMetrics.innerPadding)
        let widths = books.map { SpineGenerator.width(forPages: $0.pageCount) }
        return ShelfLayout.rows(itemWidths: widths, maxWidth: usableWidth, spacing: ShelfMetrics.spineSpacing)
    }
}

/// One shelf: books standing on a wooden board.
struct ShelfRowView: View {
    let books: [ShelfBook]
    let onSelect: (ShelfBook) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: ShelfMetrics.spineSpacing) {
                ForEach(books) { book in
                    Button {
                        onSelect(book)
                    } label: {
                        BookSpineView(book: book, shelfHeight: ShelfMetrics.shelfHeight)
                    }
                    .buttonStyle(SpineButtonStyle())
                    .accessibilityHint("Opens the book")
                }
                Spacer(minLength: 0)
            }
            .frame(height: ShelfMetrics.shelfHeight, alignment: .bottom)
            .padding(.horizontal, ShelfMetrics.innerPadding)

            ShelfPlankView()
        }
    }
}

/// Lifts the spine slightly while pressed, like pulling a book out.
struct SpineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -6 : 0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct EmptyShelfCard: View {
    let onAdd: () -> Void

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
            Button("Add your first book", action: onAdd)
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

#Preview("Demo shelf") {
    ShelfView()
        .modelContainer(Persistence.previewContainer())
}

#Preview("Empty") {
    ShelfView()
        .modelContainer(Persistence.previewContainer(withDemoBooks: false))
}
