import SwiftUI

/// A wooden shelf board: a lighter top surface and a darker front edge.
struct ShelfPlankView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.woodTop.opacity(0.85), Theme.woodTop],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.woodFront, Theme.woodShade],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(WoodGrain().opacity(0.18))
                .frame(height: 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 6, x: 0, y: 6)
        .accessibilityHidden(true)
    }
}

/// Thin horizontal grain lines, drawn the same way every time.
struct WoodGrain: View {
    var body: some View {
        Canvas { context, size in
            var y = 3.0
            var step = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                let wobble = Double((step * 7) % 5) - 2
                path.addCurve(
                    to: CGPoint(x: size.width, y: y + wobble * 0.3),
                    control1: CGPoint(x: size.width * 0.33, y: y + wobble),
                    control2: CGPoint(x: size.width * 0.66, y: y - wobble)
                )
                context.stroke(path, with: .color(.black), lineWidth: 0.6)
                y += 4
                step += 1
            }
        }
    }
}

/// The wall behind the bookshelf: warm gradient with soft vertical stripes.
struct WallBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.wallTop, Theme.wallBottom], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                let stripeWidth = 22.0
                var x = 0.0
                while x < size.width {
                    let rect = CGRect(x: x, y: 0, width: stripeWidth / 2, height: size.height)
                    context.fill(Path(rect), with: .color(Theme.wallStripe.opacity(0.18)))
                    x += stripeWidth
                }
            }
        }
        .accessibilityHidden(true)
    }
}
