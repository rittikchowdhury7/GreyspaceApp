import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.button())
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xl)
            .background(DS.Color.primary)
            .foregroundStyle(DS.Color.onPrimary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .shadow(radius: configuration.isPressed ? 0 : 6)
            .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Typography.button())
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xl)
            .background(DS.Color.surface)
            .foregroundStyle(DS.Color.onSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Color.muted.opacity(0.4), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
