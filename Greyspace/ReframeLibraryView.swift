//
//  ReframeLibraryView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-17.
//


import SwiftUI
import SwiftData

struct ReframeLibraryView: View {
    @Query(sort: \ThoughtRecord.date, order: .reverse) private var thoughts: [ThoughtRecord]
    @State private var query: String = ""
    
    /// When embedded inside another NavigationStack (e.g., History tab),
    /// set this to true so we don't create a nested NavigationStack.
    var embedded: Bool = false
    
    private var filtered: [ThoughtRecord] {
        let base = thoughts.filter { !$0.reframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        let q = query.lowercased()
        return base.filter {
            $0.reframe.lowercased().contains(q) ||
            $0.automaticThought.lowercased().contains(q) ||
            $0.emotionLabel.lowercased().contains(q) ||
            $0.situation.lowercased().contains(q)
        }
    }
    
    var body: some View {
        if embedded {
            // When embedded inside another screen (e.g., History),
            // do NOT add another NavigationStack or .searchable.
            content
        } else {
            NavigationStack {
                content
                    .navigationTitle("Reframe Library")
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search reframes…"
            )
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            VStack(spacing: DS.Spacing.sm) {
                Text("No reframes yet").font(DS.Typography.heading())
                Text("Create a Greyspace moment from the Thought Helper.")
                    .font(DS.Typography.body())
                    .foregroundStyle(DS.Color.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            let cols = [GridItem(.adaptive(minimum: 280), spacing: DS.Spacing.md)]
            ScrollView {
                LazyVGrid(columns: cols, spacing: DS.Spacing.lg) {
                    ForEach(filtered) { r in
                        NavigationLink {
                            PolaroidMomentView(
                                originalThought: r.automaticThought,
                                reframe: r.reframe,
                                onDone: { /* pop back */ },
                                startFlipped: true,
                                showTapHint: false
                            )
                            .navigationTitle("Reframe")
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            PolaroidThumbCard(
                                title: "Greyspace moment",
                                original: r.automaticThought,
                                reframe: r.reframe,
                                date: r.date
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = r.reframe
                            } label: { Label("Copy reframe", systemImage: "doc.on.doc") }
                            
                            ShareLink(item: r.reframe) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
    }
}
 
