import SwiftUI

/// Athletic-editorial theme tokens. Split into surface/ink neutrals, primary
/// brand (indigo), a pop accent (lime), macro colors, and typography helpers.
///
/// Design reference: `design/README.md` + `design/designs/styles.css`.
enum Theme {
    enum Colors {
        // Paper surfaces
        static let bg         = Color(hex: 0xF5F3EE)   // warm paper, primary app bg
        static let paper      = Color(hex: 0xFBFAF6)   // card surface
        static let line       = Color(hex: 0xE6E2D8)   // hairline border
        static let line2      = Color(hex: 0xD5D0C2)   // stronger hairline

        // Ink (dark text + dark surfaces)
        static let ink        = Color(hex: 0x0E1014)   // primary text
        static let ink2       = Color(hex: 0x2A2D33)   // secondary text
        static let ink3       = Color(hex: 0x5A5F6B)   // tertiary / captions
        static let ink4       = Color(hex: 0x9096A0)   // placeholders / disabled
        static let darkBg     = Color(hex: 0x0A0B10)   // Active-workout dark surface

        // Brand
        static let indigo     = Color(hex: 0x2B2EFF)
        static let indigo2    = Color(hex: 0x1A1D8F)
        static let indigoInk  = Color(hex: 0x0A0B3C)

        // Pop accent — used for PRs, HP badges, success
        static let lime       = Color(hex: 0xD4FF3A)
        static let limeInk    = Color(hex: 0x1F2A00)

        // Macros
        static let protein    = Color(hex: 0x1BA66A)
        static let carbs      = Color(hex: 0xE5A823)
        static let fat        = Color(hex: 0xE06A4E)
        static let kcal       = Color(hex: 0x2B2EFF)   // same as indigo

        /// Legacy SwiftUI accent (still wired via Assets.xcassets for system elements).
        static let accent     = Color("AccentColor", bundle: nil)
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 12
        static let md:  CGFloat = 16
        static let l:   CGFloat = 20
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let s:   CGFloat = 10
        static let m:   CGFloat = 14
        static let l:   CGFloat = 22
        static let xl:  CGFloat = 32
        static let pill: CGFloat = 999
    }

    /// Typography. Uses SF Pro Rounded for display (closest match to Space Grotesk
    /// without shipping custom fonts), standard SF for UI, SF Mono for data labels.
    enum Fonts {
        static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
        static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        // Preset scale used across the app.
        static let hero        = display(80, weight: .bold)   // "72" protein remaining
        static let screenTitle = display(34, weight: .bold)   // "Today", "Recipes"
        static let sectionTitle = display(22, weight: .bold)  // "Meals", "Ingredients"
        static let cardTitle   = display(20, weight: .bold)
        static let stat        = display(24, weight: .bold)   // tabular numbers
        static let body        = ui(15, weight: .regular)
        static let bodyStrong  = ui(15, weight: .semibold)
        static let caption     = ui(12, weight: .regular)
        static let micro       = mono(10, weight: .medium)    // uppercase micro-labels
    }
}

// MARK: - Color helpers

extension Color {
    /// Hex int → Color, e.g. `Color(hex: 0xF5F3EE)`.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8)  / 255.0
        let b = Double(hex & 0x0000FF)         / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
