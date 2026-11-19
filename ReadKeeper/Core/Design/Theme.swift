import SwiftUI
import UIKit

/// App colors. Placeholder palette until the real art arrives.
enum Theme {
    /// Same values as the AccentColor asset, defined in code so the widget extension (no asset catalog) matches.
    static var accent: Color { dynamic(light: 0xB5643C, dark: 0xD9885E) }

    // Wall behind the shelf
    static var wallTop: Color { dynamic(light: 0xF7EDE0, dark: 0x2B221C) }
    static var wallBottom: Color { dynamic(light: 0xEBDCC8, dark: 0x1D1713) }
    static var wallStripe: Color { dynamic(light: 0xD9C4A8, dark: 0x3A2E26) }

    // Wood
    static var woodTop: Color { dynamic(light: 0xB98455, dark: 0x8C5F3B) }
    static var woodFront: Color { dynamic(light: 0x8F5B36, dark: 0x6A4227) }
    static var woodShade: Color { dynamic(light: 0x6B3F22, dark: 0x4A2C18) }

    // Text and cards
    static var ink: Color { dynamic(light: 0x3B2A1E, dark: 0xF3E6D3) }
    static var card: Color { dynamic(light: 0xFFF9F1, dark: 0x332821) }
    static var star: Color { dynamic(light: 0xD9A23A, dark: 0xE8B95A) }
    /// Warm tint for highlighted cards (e.g. Currently reading).
    static var cardGlow: Color { dynamic(light: 0xFCE9D9, dark: 0x402E23) }

    static let spineLightText = RGB(hex: 0xF6EBD9)
    static let spineDarkText = RGB(hex: 0x2B1D14)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgbHex: dark) : UIColor(rgbHex: light)
        })
    }
}

extension Color {
    init(_ rgb: RGB) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1)
    }
}

extension UIColor {
    convenience init(rgbHex: UInt32) {
        let rgb = RGB(hex: rgbHex)
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }
}
