import SwiftUI

struct AppTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(DS.Color.primary)
            .environment(\.font, DS.Typography.body())
            .background(DS.Color.background)
    }
}

extension View {
    func appTheme() -> some View { self.modifier(AppTheme()) }
}
