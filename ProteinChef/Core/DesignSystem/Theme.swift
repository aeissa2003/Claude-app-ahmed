import SwiftUI

enum Theme {
    enum Colors {
        static let accent = Color("AccentColor", bundle: nil)
        static let protein = Color(red: 0.24, green: 0.66, blue: 0.36)
        static let carbs = Color(red: 0.97, green: 0.74, blue: 0.25)
        static let fat = Color(red: 0.91, green: 0.44, blue: 0.36)
        static let kcal = Color(red: 0.36, green: 0.49, blue: 0.90)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 20
    }
}
