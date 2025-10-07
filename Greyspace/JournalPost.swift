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
                        .font(.subheadline).fontWeight(.semibold)
                    Text(entry.date, style: .time)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(moodEmoji(entry.mood))
                    .font(.title3)
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
                                Color.secondary.opacity(0.08)
                                Image(systemName: "photo")
                                    .imageScale(.large)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    Group {
                        if entry.photos.count > 1 {
                            Text("\(selectedIndex + 1)/\(entry.photos.count)")
                                .font(.caption2).monospacedDigit()
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.black.opacity(0.45), in: Capsule())
                                .foregroundStyle(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    },
                    alignment: .topTrailing
                )
            }

            // Caption (notes)
            if !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Subtitle: gratitude + timestamp
            VStack(alignment: .leading, spacing: 4) {
                if !entry.gratitude.isEmpty {
                    Text("Gratitude: " + entry.gratitude.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Divider().opacity(0.2)
        }
        .padding(12)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Local helpers (self-contained)

private func moodColor(_ mood: Int) -> Color {
    switch mood {
    case ...2: return .red.opacity(0.85)        // low
    case 3:    return .orange.opacity(0.85)     // mid
    case 4:    return .yellow.opacity(0.85)     // good
    default:   return .green.opacity(0.85)      // great (5)
    }
}

private func anxietyColor(_ a: Int) -> Color {
    switch a {
    case 0...3:  return .green.opacity(0.85)
    case 4...6:  return .yellow.opacity(0.9)
    case 7...8:  return .orange.opacity(0.9)
    default:     return .red.opacity(0.9)
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
            Text(title).font(.caption2).bold().textCase(.uppercase)
            Text(value).font(.caption).monospacedDigit()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.18), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.55), lineWidth: 1))
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}
