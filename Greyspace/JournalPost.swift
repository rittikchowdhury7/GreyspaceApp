//
//  JournalPost.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-10.
//


// JournalPost.swift
import SwiftUI

struct JournalPost: View {
    let entry: JournalEntry
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header: date + prominent, color-coded stats
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date, style: .date)
                        .font(DS.Typography.body()).fontWeight(.semibold)
                    Text(entry.date, style: .time)
                        .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
                }
                Spacer(minLength: 8)
                Text(moodEmoji(entry.mood))
                    .font(DS.Typography.heading())
                    .accessibilityHidden(true)
                StatBadge(title: "Mood", value: "\(entry.mood)/5", color: moodColor(entry.mood))
                StatBadge(title: "Anxiety", value: "\(entry.anxiety)/10", color: anxietyColor(entry.anxiety))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mood \(entry.mood) out of 5. Anxiety \(entry.anxiety) out of 10 on \(entry.date.formatted(date: .complete, time: .shortened)).")

            // Photo carousel (swipe left/right)
            if !entry.photos.isEmpty {
                TabView(selection: $selectedIndex) {
                    // Use indices to keep type-checker happy
                    ForEach(0..<entry.photos.count, id: \.self) { idx in
                        let att = entry.photos[idx]
                        if let img = AttachmentStore.load(filename: att.filename) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 320)
                                .clipped()
                                .tag(idx)
                        } else {
                            ZStack {
                                DS.Color.surface.opacity(0.12)
                                Image(systemName: "photo")
                                    .imageScale(.large)
                                    .foregroundStyle(DS.Color.muted)
                            }
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                            .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                .overlay(
                    Group {
                        if entry.photos.count > 1 {
                            Text("\(selectedIndex + 1)/\(entry.photos.count)")
                                .font(DS.Typography.caption()).monospacedDigit()
                                .padding(.horizontal, DS.Spacing.sm)
                                .padding(.vertical, DS.Spacing.xs)
                                .background(DS.Color.background.opacity(0.7), in: Capsule())
                                .foregroundStyle(DS.Color.onSurface)
                                .padding(DS.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    },
                    alignment: .topTrailing
                )
            }

            // Caption (notes)
            if !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(DS.Typography.body())
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Subtitle: gratitude + timestamp
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                if !entry.gratitude.isEmpty {
                    Text("Gratitude: " + entry.gratitude.joined(separator: ", "))
                        .font(DS.Typography.caption())
                        .foregroundStyle(DS.Color.muted)
                        .lineLimit(2)
                }
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(DS.Typography.caption())
                    .foregroundStyle(DS.Color.muted.opacity(0.7))
            }

            Divider().overlay(DS.Color.muted.opacity(0.2))
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.surface.opacity(0.18), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.lg).stroke(DS.Color.muted.opacity(0.25), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
    }
}

// MARK: - Local helpers (self-contained)

private func moodColor(_ mood: Int) -> Color {
    switch mood {
    case ...2: return DS.Color.danger
    case 3:    return DS.Color.warning
    case 4:    return DS.Color.accent
    default:   return DS.Color.success
    }
}

private func anxietyColor(_ a: Int) -> Color {
    switch a {
    case 0...3:  return DS.Color.success
    case 4...6:  return DS.Color.warning
    case 7...8:  return DS.Color.accent
    default:     return DS.Color.danger
    }
}

private func moodEmoji(_ m: Int) -> String {
    switch m {
    case ...2: return "😔"
    case 3:    return "😐"
    case 4:    return "🙂"
    default:   return "😄"
    }
}

private struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Text(title).font(DS.Typography.caption()).bold().textCase(.uppercase)
            Text(value).font(DS.Typography.caption()).monospacedDigit()
        }
        .padding(.horizontal, DS.Spacing.md).padding(.vertical, DS.Spacing.sm)
        .background(color.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.55), lineWidth: 1))
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}
