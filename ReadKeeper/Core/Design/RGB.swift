import Foundation

/// A simple sRGB color value (0...1 per channel). Pure data, so it can be used and tested outside SwiftUI.
struct RGB: Equatable, Hashable, Sendable {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static let white = RGB(red: 1, green: 1, blue: 1)
    static let black = RGB(red: 0, green: 0, blue: 0)

    /// WCAG relative luminance (0 = black, 1 = white).
    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// Linear blend toward `other`. `amount` 0 keeps self, 1 returns `other`.
    func mixed(with other: RGB, amount: Double) -> RGB {
        let t = min(max(amount, 0), 1)
        return RGB(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t
        )
    }

    /// Hue (0..<1), saturation and lightness (0...1). Used to sort books by color.
    var hsl: (hue: Double, saturation: Double, lightness: Double) {
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let lightness = (maxValue + minValue) / 2
        let delta = maxValue - minValue
        guard delta > 0 else { return (0, 0, lightness) }

        let saturation = lightness > 0.5 ? delta / (2 - maxValue - minValue) : delta / (maxValue + minValue)
        var hue: Double
        if maxValue == red {
            hue = (green - blue) / delta + (green < blue ? 6 : 0)
        } else if maxValue == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        return (hue / 6, saturation, lightness)
    }

    /// WCAG contrast ratio between two colors (1...21).
    func contrastRatio(with other: RGB) -> Double {
        let a = relativeLuminance + 0.05
        let b = other.relativeLuminance + 0.05
        return max(a, b) / min(a, b)
    }
}
