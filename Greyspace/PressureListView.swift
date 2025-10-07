//
//  PressureListView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-08.
//

// PressureListView.swift
import SwiftUI
import SwiftData

struct PressureListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PressureSlip.trigger) private var slips: [PressureSlip]
    
    // UI
    @State private var search: String = ""
    @State private var showAdd = false
    @State private var flashPayload: FlashPayload?
    //@State private var showFlash = false
    //@State private var flashItems: [PressureSlip] = []
    //@State private var startIndex: Int = 0
    
    
    /// Expanded starter deck (non-editable seed items)
    
    // At top of file (outside the view)
    private struct FlashPayload: Identifiable {
        let id = UUID()
        let items: [PressureSlip]
        let startIndex: Int
    }
    
    private let defaultItems: [(String, String)] = [
        ("Being the translator for family (calls, forms, appointments)",
         "I’ve been resourceful for my family. It’s okay to pause, share the load, or ask for help when this role feels heavy."),
        ("Comparisons to ‘perfect’ cousins / kids",
         "I can appreciate their path and still choose mine. Growth isn’t a race; my timeline is valid."),
        ("Pressure to choose a ‘stable’ career over what you love",
         "Safety matters—and so does fulfillment. I can take small steps toward both without rejecting either."),
        ("Guilt when setting boundaries with family",
         "Boundaries protect connection. Saying ‘not right now’ can be caring—for me and for us."),
        ("Expectations around dating/marrying within culture",
         "I can honor tradition and still choose what’s healthy for me. Both love and culture deserve care."),
        ("Feeling responsible for parents’ sacrifices",
         "Their sacrifices gave me options—not a debt I must repay. Living well is a form of gratitude."),
        ("Being ‘the strong one’ who can’t show stress",
         "Strength can include asking for help. I’m allowed to need, feel, and rest."),
        ("Shame when mental health isn’t ‘a real thing’ at home",
         "My feelings are real. I can care for my mind even if others learned different rules."),
        ("Balancing two sets of norms (home vs. outside)",
         "It’s normal to feel mixed. I can take what serves me from each culture and grow my own way."),
        ("Money support expectations",
         "Helping is caring; limits are caring too. I can plan support that doesn’t sink me."),
        ("Living at home longer than peers",
         "Our paths differ. I can work toward my goals at a pace that fits my reality."),
        ("Fear of ‘disappointing’ the family",
         "Disagreement isn’t betrayal. I can communicate honestly and still belong.")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    // Header + Add
                    HStack {
                        Text("Everyday Pressures")
                            .font(DS.Typography.heading()).bold()
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.sm)
                    
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search…", text: $search)
                    }
                    .padding(DS.Spacing.md)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.Color.muted.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, DS.Spacing.lg)
                    
                    // Yours
                    if !filteredYours.isEmpty {
                        Text("Yours")
                            .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                            .padding(.horizontal, DS.Spacing.lg)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                            ForEach(filteredYours) { p in
                                MiniPressureCard(title: p.trigger)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            context.delete(p)
                                            try? context.save()
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .onTapGesture { openFlash(startingAt: p.trigger) }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.lg)
                    }
                    
                    // Starter deck
                    Text("Starter deck")
                        .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                        .padding(.horizontal, DS.Spacing.lg)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: DS.Spacing.md)], spacing: DS.Spacing.md) {
                        ForEach(filteredStarter, id: \.0) { item in
                            MiniPressureCard(title: item.0)
                                .onTapGesture { openFlash(startingAt: item.0) }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    
                    Spacer(minLength: 24)
                }
                .padding(.top, DS.Spacing.md)
            }
            .navigationTitle("Everyday Pressures")
            .onAppear { seedIfNeeded() }
            .sheet(isPresented: $showAdd) {
                AddPressureSlipSheet()
                    .presentationDetents([.medium, .large])
            }
            
            .sheet(item: $flashPayload) { payload in
                PressureFlashView(items: payload.items, startIndex: payload.startIndex)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Filtering
    
    private var filteredYours: [PressureSlip] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return slips }
        return slips.filter { $0.trigger.lowercased().contains(q) || $0.slip.lowercased().contains(q) }
    }
    
    private var filteredStarter: [(String,String)] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return defaultItems }
        return defaultItems.filter { $0.0.lowercased().contains(q) || $0.1.lowercased().contains(q) }
    }
    
    // MARK: - Seed + Open flash
    
    private func seedIfNeeded() {
        guard slips.isEmpty else { return }
        defaultItems.forEach { context.insert(PressureSlip(trigger: $0.0, slip: $0.1)) }
        try? context.save()
    }
    
    private func openFlash(startingAt title: String) {
        // Merge user + starter; user wins on duplicates by title
        var byTitle = Dictionary(uniqueKeysWithValues: slips.map { ($0.trigger, $0) })
        for (t, s) in defaultItems where byTitle[t] == nil {
            byTitle[t] = PressureSlip(trigger: t, slip: s)
        }
        let merged = Array(byTitle.values)
            .sorted { $0.trigger.localizedCaseInsensitiveCompare($1.trigger) == .orderedAscending }
        
        guard !merged.isEmpty else { return }
        let idx = merged.firstIndex(where: { $0.trigger == title }) ?? 0
        
        // Defer to next runloop so SwiftUI has all state before presenting
        DispatchQueue.main.async {
            flashPayload = FlashPayload(items: merged, startIndex: idx)
        }
    }
    
    // Small card for the grid
    private struct MiniPressureCard: View {
        let title: String
        var body: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                Spacer(minLength: 0)
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(DS.Color.muted.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
