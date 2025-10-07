//
//  PolaroidThumbCard.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-21.
//


import SwiftUI

struct PolaroidThumbCard: View {
    let title: String
    let original: String
    let reframe: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Header
            HStack(spacing: DS.Spacing.sm) {
                Text(title)
                    .font(DS.Typography.caption()).fontWeight(.semibold)
                    .foregroundStyle(DS.Color.muted)
                Spacer()
                Text(date, style: .date)
                    .font(DS.Typography.caption())
                    .foregroundStyle(DS.Color.muted)
            }

            // Card content (this drives the layout height)
            VStack(alignment: .leading, spacing: 10) {
                Text("Original")
                    .font(DS.Typography.caption()).fontWeight(.semibold)
                    .foregroundStyle(DS.Color.muted)
                Text("“\(original)”")
                    .font(DS.Typography.caption())
                    .foregroundStyle(DS.Color.muted)
                    .lineLimit(2)

                Divider().opacity(0.25)

                Text("Softer thought")
                    .font(DS.Typography.caption()).fontWeight(.semibold)
                    .foregroundStyle(DS.Color.muted)

                // Reframe callout (border sits on the container, not on Text)
                VStack(alignment: .leading, spacing: 0) {
                    Text("“\(reframe)”")
                        .font(.body.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.disabled)
                }
                .padding(DS.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(DS.Color.accent.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(DS.Spacing.md)
            .background(                // ✅ background uses the content’s size
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(DS.Color.surface)
            )
            .overlay(                   // fine to add a thin border as overlay
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(DS.Color.muted.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        }
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
    }
}
