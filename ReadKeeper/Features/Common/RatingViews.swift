import SwiftUI

/// Pure math for the star control, so it can be tested.
enum RatingMath {
    /// Rating (0.5...5 in half steps) for a touch at `x` across stars of `starWidth` separated by `spacing`.
    static func value(atX x: Double, starWidth: Double, spacing: Double) -> Double {
        let cell = starWidth + spacing
        guard cell > 0 else { return 0.5 }
        let raw = x / cell
        let halves = (raw * 2).rounded(.up) / 2
        return min(max(halves, 0.5), 5)
    }

    static func symbol(forStar index: Int, rating: Double?) -> String {
        let value = rating ?? 0
        if value >= Double(index) { return "star.fill" }
        if value >= Double(index) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    static func text(_ rating: Double?) -> String {
        guard let rating else { return "Not rated" }
        let formatted = rating.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(rating)) : String(rating)
        return "\(formatted) out of 5 stars"
    }
}

/// Tap or drag across the stars to rate in half-star steps.
struct StarRatingView: View {
    @Binding var rating: Double?
    var starSize: Double = 30

    private let spacing: Double = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: RatingMath.symbol(forStar: index, rating: rating))
                    .font(.system(size: starSize))
                    .foregroundStyle(Theme.star)
                    .frame(width: starSize, height: starSize)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newRating = RatingMath.value(atX: value.location.x, starWidth: starSize, spacing: spacing)
                    if newRating != rating {
                        rating = newRating
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue(RatingMath.text(rating))
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment: rating = min(current + 0.5, 5)
            case .decrement: rating = current <= 0.5 ? nil : current - 0.5
            @unknown default: break
            }
        }
    }
}

/// Read-only stars.
struct StarRatingDisplay: View {
    let rating: Double?
    var starSize: Double = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: RatingMath.symbol(forStar: index, rating: rating))
                    .font(.system(size: starSize))
                    .foregroundStyle(Theme.star)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(RatingMath.text(rating))
    }
}

/// 0-5 peppers. Tap a pepper to set the level; tap the highest one again to lower it.
struct SpiceLevelView: View {
    @Binding var level: Int?
    var size: Double = 26

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    level = (level ?? 0) == index ? index - 1 : index
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Text("🌶️")
                        .font(.system(size: size))
                        .opacity(index <= (level ?? 0) ? 1 : 0.22)
                        .grayscale(index <= (level ?? 0) ? 0 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Spice level")
        .accessibilityValue("\(level ?? 0) of 5")
        .accessibilityAdjustableAction { direction in
            let current = level ?? 0
            switch direction {
            case .increment: level = min(current + 1, 5)
            case .decrement: level = max(current - 1, 0)
            @unknown default: break
            }
        }
    }
}

/// Read-only peppers, e.g. "🌶️🌶️🌶️".
struct SpiceLevelDisplay: View {
    let level: Int

    var body: some View {
        Text(String(repeating: "🌶️", count: max(0, min(level, 5))))
            .font(.caption)
            .accessibilityLabel("Spice level \(level) of 5")
    }
}
