import SwiftUI

/// A book cover: the saved image, else the online cover, else a generated cover in the spine's colors.
struct CoverImageView: View {
    let data: Data?
    let url: URL?
    let title: String
    let author: String

    init(data: Data?, url: URL?, title: String, author: String) {
        self.data = data
        self.url = url
        self.title = title
        self.author = author
    }

    init(book: Book) {
        self.init(data: book.coverImageData, url: book.coverURL, title: book.title, author: book.author)
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let url {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    GeneratedCover(title: title, author: author)
                }
            }
        } else {
            GeneratedCover(title: title, author: author)
        }
    }
}

/// Simple cover drawn from the book's spine colors, used when there's no cover image.
struct GeneratedCover: View {
    let title: String
    let author: String

    var body: some View {
        let style = SpineGenerator.style(title: title, author: author, pageCount: nil)
        ZStack {
            LinearGradient(
                colors: [Color(style.base.mixed(with: .white, amount: 0.1)), Color(style.base.mixed(with: .black, amount: 0.2))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(Color(style.accent), lineWidth: 1)
                .padding(5)
            Text(title.isEmpty ? "Untitled" : title)
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(Color(style.text))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(9)
        }
    }
}
