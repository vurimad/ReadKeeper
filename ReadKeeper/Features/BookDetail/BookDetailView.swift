import SwiftData
import SwiftUI

struct BookDetailView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CoverImageView(book: book)
                    .frame(width: 150, height: 225)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(book.title)
                        .font(.title2.weight(.semibold))
                        .fontDesign(.serif)
                        .multilineTextAlignment(.center)
                    Text(book.displayAuthor)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Theme.ink)

                statusMenu

                detailsCard

                if let summary = book.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this book")
                            .font(.headline)
                        Text(summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(WallBackground().ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            BookEditorView(mode: .edit(book), draft: BookDraft(book: book))
        }
        .confirmationDialog("Delete this book?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Book", role: .destructive, action: delete)
        } message: {
            Text("This removes “\(book.title)” and its reading history from your library.")
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(ReadingStatus.allCases) { status in
                Button {
                    book.setStatus(status)
                    try? modelContext.save()
                } label: {
                    Label(status.title, systemImage: status.systemImage)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: book.status.systemImage)
                Text(book.status.title)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.headline)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.accent.opacity(0.14), in: Capsule())
        }
        .accessibilityLabel("Status: \(book.status.title)")
        .accessibilityHint("Changes the reading status")
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            DetailRow(label: "Format", value: book.format.title)
            if let pages = book.pageCount { DetailRow(label: "Pages", value: "\(pages)") }
            if let year = book.publishedYear { DetailRow(label: "Published", value: "\(year)") }
            if let publisher = book.publisher { DetailRow(label: "Publisher", value: publisher) }
            if let isbn = book.isbn13 { DetailRow(label: "ISBN", value: isbn) }
            DetailRow(label: "Added", value: book.dateAdded.formatted(date: .abbreviated, time: .omitted))
            if let started = book.dateStarted {
                DetailRow(label: "Started", value: started.formatted(date: .abbreviated, time: .omitted))
            }
            if let finished = book.dateFinished {
                DetailRow(label: "Finished", value: finished.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func delete() {
        let target = book
        let context = modelContext
        dismiss()
        // Delete after the screen has closed so it never shows a removed book.
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            context.delete(target)
            try? context.save()
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.ink)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
    }
}
