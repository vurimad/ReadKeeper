import SwiftData
import SwiftUI

struct ShelfView: View {
    @Query private var books: [Book]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(ShelfArrangement.storageKey) private var arrangementRaw = ShelfArrangement.readingFirst.rawValue

    @State private var tilt = TiltMotion()
    @State private var showingAdd = LaunchOptions.opensAddSheet
    @State private var selectedBook: Book?
    @State private var zoomSourceID = ""
    @State private var logTarget: Book?
    @Namespace private var zoomNamespace

    private var arrangement: ShelfArrangement {
        ShelfArrangement(rawValue: arrangementRaw) ?? .readingFirst
    }

    var body: some View {
        let shelfBooks = ShelfOrdering.arranged(books, by: arrangement)
        let reading = ShelfOrdering.sorted(books).filter { $0.status == .reading }

        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        if !reading.isEmpty {
                            CurrentlyReadingStrip(books: reading, namespace: zoomNamespace) { book in
                                logTarget = book
                            } onOpen: { book in
                                open(book, sourceID: CurrentlyReadingStrip.sourceID(for: book))
                            }
                        }

                        if shelfBooks.isEmpty {
                            EmptyShelfCard { showingAdd = true }
                            ForEach(0..<3, id: \.self) { _ in
                                ShelfRowView(books: [], namespace: zoomNamespace, trailingDropTarget: nil, onSelect: { _ in }, onDrop: { _, _ in })
                            }
                        } else {
                            let shelfRows = rows(for: shelfBooks, width: proxy.size.width)
                            TiltingShelf {
                                VStack(spacing: 28) {
                                    ForEach(Array(shelfRows.enumerated()), id: \.element) { index, range in
                                        let nextRowFirst: UUID? = index + 1 < shelfRows.count
                                            ? shelfBooks[shelfRows[index + 1].lowerBound].id
                                            : nil
                                        ShelfRowView(
                                            books: shelfBooks[range].map(\.shelfBook),
                                            namespace: zoomNamespace,
                                            trailingDropTarget: nextRowFirst
                                        ) { tapped in
                                            if let book = shelfBooks.first(where: { $0.id == tapped.id }) {
                                                open(book, sourceID: ShelfRowView.sourceID(for: book.id))
                                            }
                                        } onDrop: { dragged, target in
                                            move(dragged, before: target, in: shelfBooks)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ShelfMetrics.outerPadding)
                    .padding(.vertical, 16)
                }
            }
            .background(TiltingWall())
            .navigationTitle("My Shelf")
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(book: book)
                    .navigationTransition(.zoom(sourceID: zoomSourceID, in: zoomNamespace))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    arrangementMenu
                }
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
            .sheet(item: $logTarget) { book in
                LogProgressSheet(book: book)
            }
            .task {
                if let title = LaunchOptions.openBookTitle, selectedBook == nil,
                   let book = books.first(where: { $0.title == title }) {
                    open(book, sourceID: ShelfRowView.sourceID(for: book.id))
                }
            }
        }
        .environment(tilt)
        .onAppear { tilt.start() }
        .onDisappear { tilt.stop() }
    }

    private var arrangementMenu: some View {
        Menu {
            Picker("Arrange", selection: $arrangementRaw) {
                ForEach(ShelfArrangement.allCases) { option in
                    Label(option.title, systemImage: option.systemImage).tag(option.rawValue)
                }
            }
            Text("Press and hold a book to move it.")
        } label: {
            Label("Arrange", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Arrange shelf, currently \(arrangement.title)")
    }

    private func open(_ book: Book, sourceID: String) {
        zoomSourceID = sourceID
        selectedBook = book
    }

    private func rows(for books: [Book], width: Double) -> [Range<Int>] {
        let usableWidth = width - 2 * (ShelfMetrics.outerPadding + ShelfMetrics.innerPadding)
        let widths = books.map { SpineGenerator.width(forPages: $0.pageCount) }
        return ShelfLayout.rows(itemWidths: widths, maxWidth: usableWidth, spacing: ShelfMetrics.spineSpacing)
    }

    /// Drops `dragged` before `target` and switches the shelf to "My Order".
    private func move(_ dragged: UUID, before target: UUID?, in current: [Book]) {
        let newOrder = ShelfOrdering.reordered(current.map(\.id), moving: dragged, before: target)
        let booksByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        withAnimation(.snappy) {
            for (index, id) in newOrder.enumerated() {
                booksByID[id]?.shelfOrder = Double(index + 1)
            }
            arrangementRaw = ShelfArrangement.custom.rawValue
        }
        try? modelContext.save()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

/// One shelf: books standing on a wooden board.
struct ShelfRowView: View {
    let books: [ShelfBook]
    let namespace: Namespace.ID
    /// Where a book dropped on the empty end of this row goes (before the next row's first book).
    let trailingDropTarget: UUID?
    let onSelect: (ShelfBook) -> Void
    let onDrop: (_ dragged: UUID, _ target: UUID?) -> Void

    @Environment(\.shelfTilt) private var tilt

    static func sourceID(for id: UUID) -> String { "spine-\(id.uuidString)" }

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
                    .matchedTransitionSource(id: Self.sourceID(for: book.id), in: namespace)
                    .draggable(book.id.uuidString) {
                        BookSpineView(book: book, shelfHeight: ShelfMetrics.shelfHeight)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let dragged = items.first.flatMap(UUID.init(uuidString:)), dragged != book.id else {
                            return false
                        }
                        onDrop(dragged, book.id)
                        return true
                    }
                    .accessibilityHint("Opens the book. Press and hold to move it.")
                }

                // Empty end of the shelf: drop a book here to put it at the end of this row.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { items, _ in
                        guard let dragged = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                        onDrop(dragged, trailingDropTarget)
                        return true
                    }
            }
            .frame(height: ShelfMetrics.shelfHeight, alignment: .bottom)
            .padding(.horizontal, ShelfMetrics.innerPadding)
            // Books sit in front of the wall, so they shift a little more than the shelf board.
            .offset(x: tilt.width * 3, y: tilt.height * 1.5)

            ShelfPlankView()
        }
    }
}

/// Lifts the spine slightly while pressed, like pulling a book out.
struct SpineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -8 : 0)
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
