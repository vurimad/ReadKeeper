import SwiftUI

/// Find a book (search or barcode) or add one by hand.
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = LaunchOptions.initialSearchQuery ?? ""
    @State private var phase: SearchPhase = .idle
    @State private var results: [BookSearchResult] = []
    @State private var editorDraft: DraftItem?
    @State private var showingScanner = false

    private let searchService = BookSearchService.live

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Scan a barcode", systemImage: "barcode.viewfinder")
                    }
                    .disabled(!BarcodeScanner.isAvailable)

                    Button {
                        editorDraft = DraftItem(draft: BookDraft())
                    } label: {
                        Label("Add manually", systemImage: "square.and.pencil")
                    }
                } footer: {
                    if !BarcodeScanner.isAvailable {
                        Text("Barcode scanning needs a camera. You can type the ISBN in the search field instead.")
                    }
                }

                resultsSection
            }
            .navigationTitle("Add a Book")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Title, author or ISBN"
            )
            .autocorrectionDisabled()
            .task(id: query) { await runSearch() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerSheet { isbn in query = isbn }
            }
            .sheet(item: $editorDraft) { item in
                BookEditorView(mode: .create, draft: item.draft) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .searching:
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Searching…").foregroundStyle(.secondary)
                }
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "wifi.exclamationmark")
                    .foregroundStyle(.secondary)
            }
        case .loaded:
            if results.isEmpty {
                Section {
                    Text("No books found. Try another spelling, the ISBN, or add it manually.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Results") {
                    ForEach(results) { result in
                        Button {
                            editorDraft = DraftItem(draft: BookDraft(result: result))
                        } label: {
                            SearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmed
        guard trimmed.count >= 2 else {
            phase = .idle
            results = []
            return
        }
        // Wait until the user pauses typing; a newer query cancels this one.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        phase = .searching
        do {
            let found = try await searchService.search(trimmed)
            guard !Task.isCancelled else { return }
            results = found
            phase = .loaded
        } catch is CancellationError {
            // A newer search replaced this one.
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            phase = .failed("Couldn't reach the book catalogs. Check your connection and try again.")
        }
    }
}

enum SearchPhase: Equatable {
    case idle
    case searching
    case loaded
    case failed(String)
}

/// Wraps a draft so it can drive `.sheet(item:)`.
struct DraftItem: Identifiable {
    let id = UUID()
    var draft: BookDraft
}

struct SearchResultRow: View {
    let result: BookSearchResult

    var body: some View {
        HStack(spacing: 14) {
            CoverImageView(data: nil, url: result.coverURL, title: result.title, author: result.authorLine)
                .frame(width: 46, height: 69)

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                if !result.authorLine.isEmpty {
                    Text(result.authorLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.accent)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Adds this book")
    }

    private var details: String {
        [result.publishedYear.map(String.init), result.pageCount.map { "\($0) pages" }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

#Preview {
    AddBookView()
        .modelContainer(Persistence.previewContainer(withDemoBooks: false))
}
