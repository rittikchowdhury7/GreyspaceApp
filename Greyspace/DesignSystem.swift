import SwiftUI

enum DS {
    enum Color {
        static let primary = SwiftUI.Color("Primary")
        static let onPrimary = SwiftUI.Color("OnPrimary")
        static let background = SwiftUI.Color("Background")
        static let surface = SwiftUI.Color("Surface")
        static let onSurface = SwiftUI.Color("OnSurface")
        static let muted = SwiftUI.Color("Muted")
        static let accent = SwiftUI.Color("Accent")
        static let danger = SwiftUI.Color("Danger")
        static let success = SwiftUI.Color("Success")
        static let warning = SwiftUI.Color("Warning")
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
