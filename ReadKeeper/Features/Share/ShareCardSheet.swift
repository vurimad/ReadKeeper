import SwiftData
import SwiftUI

enum ShareCardKind: Identifiable {
    case shelf
    case book(Book)
    case year

    var id: String {
        switch self {
        case .shelf: "shelf"
        case .book(let book): "book-\(book.id.uuidString)"
        case .year: "year"
        }
    }

    var title: String {
        switch self {
        case .shelf: "My Shelf"
        case .book(let book): book.title
        case .year: "My Year in Books"
        }
    }
}

/// Renders a share card to an image and offers the system share sheet (Instagram, TikTok, Messages, Save Image…).
struct ShareCardSheet: View {
    let kind: ShareCardKind

    @Query private var books: [Book]
    @AppStorage(ReadingGoal.storageKey) private var goal = 0
    @AppStorage(ShelfArrangement.storageKey) private var arrangementRaw = ShelfArrangement.readingFirst.rawValue
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
                        .padding(.horizontal, 36)

                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(kind.title, image: Image(uiImage: image))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: 260)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                } else {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { render() }
        }
    }

    @ViewBuilder
    private var card: some View {
        let year = Calendar.current.component(.year, from: .now)
        switch kind {
        case .shelf:
            let arrangement = ShelfArrangement(rawValue: arrangementRaw) ?? .readingFirst
            let shelf = ShelfOrdering.arranged(books, by: arrangement)
            let finished = ReadingGoal.booksFinished(in: year, finishDates: books.compactMap(\.dateFinished))
            ShelfShareCard(books: shelf, subtitle: "\(shelf.count) books · \(finished) read in \(String(year))")
        case .book(let book):
            BookShareCard(book: book)
        case .year:
            let streak = StreakCalculator.summary(activityDays: ReadingActivity.activityDays(books: books), today: .now)
            YearShareCard(stats: YearStats.compute(books: books, year: year), goal: goal, streakDays: streak.current)
        }
    }

    private func render() {
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = 3
        image = renderer.uiImage
    }
}
