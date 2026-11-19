import SwiftData
import SwiftUI

enum LibraryFilter: Hashable, CaseIterable, Identifiable {
    case all
    case reading
    case wantToRead
    case read
    case dnf

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .reading: ReadingStatus.reading.title
        case .wantToRead: ReadingStatus.wantToRead.title
        case .read: ReadingStatus.read.title
        case .dnf: ReadingStatus.dnf.shortTitle
        }
    }

    func matches(_ status: ReadingStatus) -> Bool {
        switch self {
        case .all: true
        case .reading: status == .reading
        case .wantToRead: status == .wantToRead
        case .read: status == .read
        case .dnf: status == .dnf
        }
    }
}

struct LibraryView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @Environment(\.modelContext) private var modelContext

    @State private var filter: LibraryFilter = .all
    @State private var searchText = ""
    @State private var showingAdd = false

    private var visibleBooks: [Book] {
        let query = searchText.trimmed
        return books.filter { book in
            guard filter.matches(book.status) else { return false }
            guard !query.isEmpty else { return true }
            return book.title.localizedCaseInsensitiveContains(query)
                || book.author.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    ContentUnavailableView {
                        Label("Your library is empty", systemImage: "books.vertical")
                    } description: {
                        Text("Add the books you're reading, have read, or want to read.")
                    } actions: {
                        Button("Add a Book") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                    }
                } else {
                    List {
                        Section {
                            filterChips
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                        Section {
                            ForEach(visibleBooks) { book in
                                NavigationLink(value: book) {
                                    BookRowView(book: book)
                                }
                            }
                            .onDelete(perform: delete)
                        } footer: {
                            if visibleBooks.isEmpty {
                                Text(searchText.trimmed.isEmpty ? "No books here yet." : "No books match your search.")
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search your books")
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { book in
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

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { option in
                    let count = books.filter { option.matches($0.status) }.count
                    Button {
                        filter = option
                    } label: {
                        Text("\(option.title) \(count)")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(filter == option ? Color.white : Theme.ink)
                            .background(
                                filter == option ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.card),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func delete(at offsets: IndexSet) {
        let targets = offsets.map { visibleBooks[$0] }
        for book in targets {
            modelContext.delete(book)
        }
        try? modelContext.save()
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 14) {
            CoverImageView(book: book)
                .frame(width: 46, height: 69)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.displayAuthor)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label(book.status.shortTitle, systemImage: book.status.systemImage)
                        .foregroundStyle(Theme.accent)
                    if let pages = book.pageCount {
                        Text("· \(pages) pages")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LibraryView()
        .modelContainer(Persistence.previewContainer())
}
