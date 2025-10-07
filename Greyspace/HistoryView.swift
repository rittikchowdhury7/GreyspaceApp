//
//  HistoryView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI
import SwiftData

struct HistoryView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case entries = "Entries"
        case reframes = "Reframes"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var kind: Kind = .entries
    @State private var query: String = ""
    @State private var sortNewestFirst: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $kind) {
                    ForEach(Kind.allCases) { k in Text(k.rawValue).tag(k) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, DS.Spacing.sm)
                .onChange(of: kind) { if $0 == .reframes { query = "" } }

                if kind == .entries {
                    // Entries feed + its OWN search
                    entriesFeed
                        .searchable(text: $query,
                                    placement: .navigationBarDrawer(displayMode: .always),
                                    prompt: "Search notes, gratitude…")
                } else {
                    // Reframes grid (no extra List or searchable here)
                    ReframeLibraryView(embedded: true)
                        .padding(.top, DS.Spacing.sm)
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: Entries feed

    private var entriesFeed: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                if filteredEntries.isEmpty {
                    EmptyStateView(title: "No entries yet",
                                   subtitle: "Log a quick check-in on the Today tab.")
                        .padding(.top, DS.Spacing.xl)
                } else {
                    ForEach(filteredEntries) { e in
                        JournalPost(entry: e)
                            .contextMenu {
                                Button { shareEntry(e) } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                Button(role: .destructive) {
                                    e.photos.forEach { AttachmentStore.delete(filename: $0.filename) }
                                    context.delete(e)
                                    try? context.save()
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    private var filteredEntries: [JournalEntry] {
        let base = entries.sorted { sortNewestFirst ? $0.date > $1.date : $0.date < $1.date }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter { e in
            let fields = [
                e.notes.lowercased(),
                e.gratitude.joined(separator: " ").lowercased(),
                e.tags.joined(separator: " ").lowercased(),
                e.date.formatted(date: .numeric, time: .shortened).lowercased()
            ]
            return fields.contains { $0.contains(q) }
        }
    }

    private func shareEntry(_ e: JournalEntry) {
        let text = JournalShareFormatter.text(for: e)
        let imgs = e.photos.compactMap { AttachmentStore.load(filename: $0.filename) }
        let items: [Any] = [text] + imgs
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
    }
}

private struct EmptyStateView: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(DS.Typography.heading())
            Text(subtitle).font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xl)
    }
}

enum JournalShareFormatter {
    static func text(for e: JournalEntry) -> String {
        var parts = [String]()
        parts.append("Date: \(e.date.formatted(date: .complete, time: .shortened))")
        parts.append("Mood: \(e.mood)/5  •  Anxiety: \(e.anxiety)/10")
        if !e.gratitude.isEmpty { parts.append("Gratitude: " + e.gratitude.joined(separator: ", ")) }
        if !e.notes.isEmpty { parts.append("Notes: \(e.notes)") }
        if e.didMindfulness { parts.append("Mindfulness: ✓") }
        if !e.photos.isEmpty { parts.append("Photos: \(e.photos.count)") }
        return parts.joined(separator: "\n")
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
