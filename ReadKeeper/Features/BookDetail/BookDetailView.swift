import SwiftData
import SwiftUI

struct BookDetailView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var showingLog = LaunchOptions.opensLogSheet
    @State private var showingReview = false
    @State private var showingAddQuote = false
    @State private var confirmingDelete = false
    @State private var shareCard: ShareCardKind?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                statusMenu

                if book.status == .reading || book.progressValue > 0 {
                    progressCard
                }
                thoughtsCard
                quotesCard
                if !book.sortedLogs.isEmpty {
                    historyCard
                }
                detailsCard
                if let summary = book.summary, !summary.isEmpty {
                    card(title: "About this book") {
                        Text(summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                        shareCard = .book(book)
                    } label: {
                        Label("Share Book Card", systemImage: "square.and.arrow.up")
                    }
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
        .sheet(isPresented: $showingLog) {
            LogProgressSheet(book: book)
        }
        .sheet(isPresented: $showingReview) {
            ReviewEditorSheet(book: book)
        }
        .sheet(isPresented: $showingAddQuote) {
            AddQuoteSheet(book: book)
        }
        .sheet(item: $shareCard) { kind in
            ShareCardSheet(kind: kind)
        }
        .confirmationDialog("Delete this book?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Book", role: .destructive, action: delete)
        } message: {
            Text("This removes “\(book.title)” and its reading history from your library.")
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 14) {
            CoverImageView(book: book)
                .frame(width: 150, height: 225)
                .padding(.top, 8)
            VStack(spacing: 6) {
                Text(book.title)
                    .font(.title2.weight(.semibold))
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                Text(book.displayAuthor)
                    .foregroundStyle(.secondary)
                if book.rating != nil {
                    StarRatingDisplay(rating: book.rating, starSize: 16)
                        .padding(.top, 2)
                }
            }
            .foregroundStyle(Theme.ink)
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

    private var progressCard: some View {
        card(title: "Progress") {
            VStack(alignment: .leading, spacing: 10) {
                if let fraction = book.progressFraction {
                    ReadingProgressBar(fraction: fraction)
                }
                HStack {
                    Text(book.progressText)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if let fraction = book.progressFraction {
                        Text("\(Int((fraction * 100).rounded()))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    showingLog = true
                } label: {
                    Label("Log Progress", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
            }
        }
    }

    private var thoughtsCard: some View {
        card(title: "Your thoughts") {
            VStack(alignment: .leading, spacing: 10) {
                if book.hasThoughts {
                    if let rating = book.rating {
                        HStack {
                            StarRatingDisplay(rating: rating, starSize: 18)
                            Text(RatingMath.text(rating))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let spice = book.spiceLevel, spice > 0 {
                        SpiceLevelDisplay(level: spice)
                    }
                    if !(book.tropes + book.tags).isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(book.tropes, id: \.self) { ChipView(text: $0) }
                            ForEach(book.tags, id: \.self) { ChipView(text: "#\($0)", isSelected: false) }
                        }
                    }
                    if let review = book.review {
                        Text(review)
                            .font(.callout)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(6)
                    }
                }
                Button(book.hasThoughts ? "Edit Rating & Review" : "Rate & Review") {
                    showingReview = true
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var quotesCard: some View {
        card(title: "Quotes") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(book.sortedQuotes) { quote in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("“\(quote.text)”")
                            .font(.callout)
                            .fontDesign(.serif)
                            .italic()
                            .foregroundStyle(Theme.ink)
                        if let page = quote.page {
                            Text("p. \(page)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(quote)
                            try? modelContext.save()
                        } label: {
                            Label("Delete Quote", systemImage: "trash")
                        }
                    }
                }
                Button {
                    showingAddQuote = true
                } label: {
                    Label("Add Quote", systemImage: "quote.opening")
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var historyCard: some View {
        card(title: "Reading history") {
            VStack(spacing: 0) {
                ForEach(book.sortedLogs.prefix(8)) { log in
                    HStack {
                        Text(log.date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(log.amountText)
                            .foregroundStyle(log.amount >= 0 ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.secondary))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(log)
                            try? modelContext.save()
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var detailsCard: some View {
        card(title: "Details") {
            VStack(spacing: 0) {
                DetailRow(label: "Format", value: book.format.title)
                if let pages = book.pageCount { DetailRow(label: "Pages", value: "\(pages)") }
                if let minutes = book.totalMinutes {
                    DetailRow(label: "Length", value: ProgressMath.durationText(minutes: Double(minutes)))
                }
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
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
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
        .padding(.vertical, 8)
    }
}
