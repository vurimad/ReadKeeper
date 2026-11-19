import Foundation

enum SpinePattern: CaseIterable, Sendable {
    case plain
    case bands
    case doubleBands
    case frame
}

/// Everything needed to draw one generated book spine.
struct SpineStyle: Equatable, Sendable {
    let base: RGB
    let accent: RGB
    let text: RGB
    /// Spine height as a fraction of the shelf height (0.80...0.98).
    let heightFactor: Double
    /// Spine thickness in points, based on page count.
    let width: Double
    let pattern: SpinePattern
}

/// Generates a good-looking spine for any book from its title, author and page count.
/// The same book always gets the same spine.
enum SpineGenerator {
    static let minWidth: Double = 18
    static let maxWidth: Double = 46
    static let defaultWidth: Double = 28

    /// Cozy, bookish base colors.
    static let palette: [RGB] = [
        RGB(hex: 0x7A2E2E), // oxblood
        RGB(hex: 0x2F4A3A), // forest green
        RGB(hex: 0x1F3A5A), // navy
        RGB(hex: 0xC9A66B), // mustard
        RGB(hex: 0xD8C3A5), // linen
        RGB(hex: 0x5B3A5E), // plum
        RGB(hex: 0xB5643C), // terracotta
        RGB(hex: 0x3E5F6E), // slate teal
        RGB(hex: 0xE6D7C3), // cream
        RGB(hex: 0x8A9A5B), // sage
        RGB(hex: 0x2B2B2B), // charcoal
        RGB(hex: 0xC97B84), // dusty rose
    ]

    private static let gold = RGB(hex: 0xE2C27D)
    private static let espresso = RGB(hex: 0x3A2618)

    static func style(title: String, author: String, pageCount: Int?) -> SpineStyle {
        let seed = StableHash.mix(StableHash.fnv1a("\(normalized(title))|\(normalized(author))"))

        let base = palette[Int(seed % UInt64(palette.count))]
        let isDark = base.relativeLuminance < 0.35
        let accent = isDark ? base.mixed(with: gold, amount: 0.75) : base.mixed(with: espresso, amount: 0.6)
        let text = textColor(on: base)

        let heightFactor = 0.80 + Double((seed >> 16) % 19) / 100.0
        let patterns = SpinePattern.allCases
        let pattern = patterns[Int((seed >> 24) % UInt64(patterns.count))]

        return SpineStyle(
            base: base,
            accent: accent,
            text: text,
            heightFactor: heightFactor,
            width: width(forPages: pageCount),
            pattern: pattern
        )
    }

    /// Thicker books get thicker spines, clamped to a sensible range.
    static func width(forPages pages: Int?) -> Double {
        guard let pages, pages > 0 else { return defaultWidth }
        return min(max(Double(pages) / 14.0, minWidth), maxWidth)
    }

    /// Picks whichever text color reads better on the spine.
    static func textColor(on base: RGB) -> RGB {
        let light = Theme.spineLightText
        let dark = Theme.spineDarkText
        return base.contrastRatio(with: light) >= base.contrastRatio(with: dark) ? light : dark
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
