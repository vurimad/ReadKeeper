import SwiftUI

/// One generated book spine standing on the shelf.
struct BookSpineView: View {
    let book: ShelfBook
    let shelfHeight: Double

    var body: some View {
        let style = SpineGenerator.style(title: book.title, author: book.author, pageCount: book.pageCount)
        let height = shelfHeight * style.heightFactor

        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(style.base.mixed(with: .white, amount: 0.14)),
                            Color(style.base),
                            Color(style.base.mixed(with: .black, amount: 0.28)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            SpineDecoration(pattern: style.pattern, accent: Color(style.accent))

            VStack(spacing: 0) {
                Text(book.title)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(style.text))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: max(height - 44, 20))
                    .rotationEffect(.degrees(-90))
                    .frame(width: style.width, height: height - 26)

                Text(book.authorInitials)
                    .font(.system(size: 8, weight: .bold, design: .serif))
                    .foregroundStyle(Color(style.text).opacity(0.85))
                    .frame(height: 14)
            }
            .frame(width: style.width, height: height)
        }
        .frame(width: style.width, height: height)
        .shadow(color: .black.opacity(0.28), radius: 1.5, x: 1, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(book.title) by \(book.author)")
    }
}

/// Decorative bands and frames printed on a spine.
struct SpineDecoration: View {
    let pattern: SpinePattern
    let accent: Color

    var body: some View {
        switch pattern {
        case .plain:
            Color.clear
        case .bands:
            VStack(spacing: 0) {
                band.padding(.top, 10)
                Spacer()
                band.padding(.bottom, 20)
            }
        case .doubleBands:
            VStack(spacing: 0) {
                VStack(spacing: 3) { band; band }.padding(.top, 8)
                Spacer()
                VStack(spacing: 3) { band; band }.padding(.bottom, 18)
            }
        case .frame:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(accent, lineWidth: 1)
                .padding(4)
        }
    }

    private var band: some View {
        Rectangle()
            .fill(accent)
            .frame(height: 2.5)
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: 2) {
        ForEach(DemoLibrary.books.prefix(8)) { book in
            BookSpineView(book: book, shelfHeight: 150)
        }
    }
    .padding()
}
