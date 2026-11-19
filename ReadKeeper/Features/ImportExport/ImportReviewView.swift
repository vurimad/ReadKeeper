import SwiftData
import SwiftUI

/// Shows what an import will add before anything is saved. Tap a book to leave it out.
struct ImportReviewView: View {
    let plan: ImportPlan

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var excluded: Set<UUID> = []
    @State private var importedCount: Int?

    private var selectedBooks: [ImportedBook] {
        plan.books.filter { !excluded.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let importedCount {
                    successView(count: importedCount)
                } else {
                    reviewList
                }
            }
            .navigationTitle(importedCount == nil ? "Review Import" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if importedCount == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import \(selectedBooks.count)") { runImport() }
                            .disabled(selectedBooks.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: Review

    private var reviewList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(plan.books.count) new \(plan.books.count == 1 ? "book" : "books") from \(plan.source.title)")
                        .font(.title3.weight(.semibold))
                        .fontDesign(.serif)
                    HStack(spacing: 8) {
                        countPill(.read)
                        countPill(.reading)
                        countPill(.wantToRead)
                        countPill(.dnf)
                    }
                    if plan.withoutISBN > 0 {
                        Label(
                            "\(plan.withoutISBN) without an ISBN will get a generated cover. You can change any cover later.",
                            systemImage: "info.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            if !plan.alreadyInLibrary.isEmpty {
                Section {
                    DisclosureGroup("\(plan.alreadyInLibrary.count) already in your library (skipped)") {
                        ForEach(plan.alreadyInLibrary) { book in
                            ImportRow(book: book, isIncluded: false)
                        }
                    }
                }
            }

            Section {
                ForEach(plan.books) { book in
                    Button {
                        toggle(book)
                    } label: {
                        ImportRow(book: book, isIncluded: !excluded.contains(book.id))
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Books to import")
            } footer: {
                Text("Tap a book to leave it out.")
            }
        }
    }

    private func countPill(_ status: ReadingStatus) -> some View {
        VStack(spacing: 2) {
            Text("\(plan.count(of: status))")
                .font(.headline)
                .monospacedDigit()
            Text(status.shortTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggle(_ book: ImportedBook) {
        if excluded.contains(book.id) {
            excluded.remove(book.id)
        } else {
            excluded.insert(book.id)
        }
    }

    private func runImport() {
        let books = selectedBooks
        let now = Date.now
        for book in books {
            modelContext.insert(book.makeBook(now: now))
        }
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { importedCount = books.count }
    }

    // MARK: Done

    private func successView(count: Int) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("Welcome home, books!")
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
            Text("\(count) \(count == 1 ? "book is" : "books are") now on your shelf.")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WallBackground().ignoresSafeArea())
    }
}

private struct ImportRow: View {
    let book: ImportedBook
    let isIncluded: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isIncluded ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.tertiary))

            CoverImageView(data: nil, url: book.coverURL, title: book.title, author: book.author)
                .frame(width: 34, height: 51)

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(book.author.isEmpty ? "Unknown Author" : book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(book.status.shortTitle)
                        .foregroundStyle(Theme.accent)
                    if let rating = book.rating {
                        StarRatingDisplay(rating: rating, starSize: 9)
                    }
                    if book.isbn13 == nil {
                        Text("No ISBN")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.caption2)
            }
            Spacer(minLength: 0)
        }
        .opacity(isIncluded ? 1 : 0.55)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(isIncluded ? "Will be imported" : "Left out")
    }
}
