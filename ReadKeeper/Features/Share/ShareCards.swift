import SwiftUI

/// Story-sized cards (9:16) rendered to images for TikTok and Instagram.
/// Drawn at 360×640 points and exported at 3× = 1080×1920 pixels.
enum ShareCardMetrics {
    static let size = CGSize(width: 360, height: 640)
}

/// Small "ReadKeeper" mark at the bottom of every card.
struct ShareWatermark: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "books.vertical.fill")
            Text("ReadKeeper")
                .fontDesign(.serif)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.ink.opacity(0.55))
    }
}

/// Cover for share cards: saved image or generated cover (no network images, which can't be rendered).
struct ShareCover: View {
    let book: Book

    var body: some View {
        Group {
            if let data = book.coverImageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                GeneratedCover(title: book.title, author: book.author)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 4, y: 8)
    }
}

// MARK: - My Shelf

struct ShelfShareCard: View {
    let books: [Book]
    let subtitle: String

    private let shelfHeight: Double = 104

    var body: some View {
        let rows = ShelfLayout.rows(
            itemWidths: books.map { SpineGenerator.width(forPages: $0.pageCount) },
            maxWidth: ShareCardMetrics.size.width - 2 * (20 + ShelfMetrics.innerPadding),
            spacing: ShelfMetrics.spineSpacing
        ).prefix(4)

        VStack(alignment: .leading, spacing: 0) {
            Text("My Shelf")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .padding(.top, 2)

            Spacer(minLength: 18)

            VStack(spacing: 22) {
                ForEach(Array(rows), id: \.self) { range in
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom, spacing: ShelfMetrics.spineSpacing) {
                            ForEach(books[range].map(\.shelfBook)) { book in
                                BookSpineView(book: book, shelfHeight: shelfHeight)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(height: shelfHeight, alignment: .bottom)
                        .padding(.horizontal, ShelfMetrics.innerPadding)
                        ShelfPlankView()
                    }
                }
            }

            Spacer(minLength: 18)
            ShareWatermark()
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .padding(.top, 20)
        .frame(width: ShareCardMetrics.size.width, height: ShareCardMetrics.size.height)
        .background(WallBackground())
    }
}

// MARK: - One book

struct BookShareCard: View {
    let book: Book

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            ShareCover(book: book)
                .frame(width: 170, height: 255)

            Text(book.title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(.top, 26)
            Text(book.displayAuthor)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .padding(.top, 4)

            if book.rating != nil {
                StarRatingDisplay(rating: book.rating, starSize: 22)
                    .padding(.top, 14)
            }
            if let spice = book.spiceLevel, spice > 0 {
                Text(String(repeating: "🌶️", count: spice))
                    .font(.system(size: 16))
                    .padding(.top, 6)
            }

            if let line = highlight {
                Text("“\(line)”")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .lineLimit(4)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
            }

            Spacer(minLength: 16)
            if let finished = book.dateFinished, book.status == .read {
                Text("Finished \(finished.formatted(.dateTime.month(.wide).year()))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 8)
            }
            ShareWatermark()
        }
        .padding(24)
        .frame(width: ShareCardMetrics.size.width, height: ShareCardMetrics.size.height)
        .background(
            LinearGradient(colors: [Theme.card, Theme.cardGlow], startPoint: .top, endPoint: .bottom)
        )
    }

    /// The review if there is one, otherwise the newest quote.
    private var highlight: String? {
        if let review = book.review?.nilIfBlank { return review }
        return book.sortedQuotes.first?.text
    }
}

// MARK: - My year

struct YearShareCard: View {
    let stats: YearStats
    let goal: Int
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("My \(String(stats.year))\nin Books")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(-2)

            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle().stroke(Theme.ink.opacity(0.1), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: goal > 0 ? min(Double(stats.booksFinished) / Double(goal), 1) : 1)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(stats.booksFinished)")
                            .font(.system(size: 40, weight: .bold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text(goal > 0 ? "of \(goal) books" : "books")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 10) {
                    statLine(value: stats.pagesFinished.formatted(), label: "pages")
                    if let average = stats.averageRating {
                        statLine(value: String(format: "%.1f★", average), label: "average rating")
                    }
                    if streakDays > 0 {
                        statLine(value: "\(streakDays) days", label: "reading streak")
                    }
                }
            }
            .padding(.top, 26)

            if !stats.topTropes.isEmpty {
                Text("Favorite tropes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                    .padding(.top, 26)
                FlowLayout(spacing: 6) {
                    ForEach(stats.topTropes, id: \.self) { ChipView(text: $0) }
                }
                .padding(.top, 8)
            }

            if let title = stats.longestBookTitle, let pages = stats.longestBookPages {
                Text("Longest read")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                    .padding(.top, 20)
                Text("\(title) · \(pages) pages")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)
            }

            Spacer(minLength: 16)
            ShareWatermark()
                .frame(maxWidth: .infinity)
        }
        .padding(26)
        .padding(.top, 24)
        .frame(width: ShareCardMetrics.size.width, height: ShareCardMetrics.size.height)
        .background(WallBackground())
    }

    private func statLine(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }
}
