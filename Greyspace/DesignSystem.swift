import SwiftUI

enum DS {
    enum Color {
        static let primary = Color("Primary")
        static let onPrimary = Color("OnPrimary")
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let onSurface = Color("OnSurface")
        static let muted = Color("Muted")
        static let accent = Color("Accent")
        static let danger = Color("Danger")
        static let success = Color("Success")
        static let warning = Color("Warning")
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    enum Typography {
        static func display() -> Font { .custom("OpenSans-Black", size: 34, relativeTo: .largeTitle) }
        static func title() -> Font { .custom("OpenSans-SemiBold", size: 28, relativeTo: .title) }
        static func heading() -> Font { .custom("OpenSans-Medium", size: 20, relativeTo: .headline) }
        static func body() -> Font { .custom("OpenSans-Regular", size: 16, relativeTo: .body) }
        static func caption() -> Font { .custom("OpenSans-Light", size: 13, relativeTo: .caption) }
        static func thinDisplay() -> Font { .custom("OpenSans-Thin", size: 42, relativeTo: .largeTitle) }
    }
}
