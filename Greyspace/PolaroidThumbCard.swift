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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Card content (this drives the layout height)
            VStack(alignment: .leading, spacing: 10) {
                Text("Original")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("“\(original)”")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Divider().opacity(0.25)

                Text("Softer thought")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                // Reframe callout (border sits on the container, not on Text)
                VStack(alignment: .leading, spacing: 0) {
                    Text("“\(reframe)”")
                        .font(.body.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.disabled)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(14)
            .background(                // ✅ background uses the content’s size
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(                   // fine to add a thin border as overlay
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
