//
//  PressurePointsView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-08.
//
import SwiftUI
import SwiftData
import AVFoundation

struct PressurePointSlip: View {
    let trigger: String
    let slip: String
    @State private var copied = false
    private let speech = AVSpeechSynthesizer()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trigger).font(.headline)
            Text(slip).font(.body)

            HStack {
                Button {
                    UIPasteboard.general.string = slip
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copied = false }
                } label: { Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc") }

                Button {
                    let utt = AVSpeechUtterance(string: slip)
                    utt.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speech.speak(utt)
                } label: { Label("Play", systemImage: "speaker.wave.2") }

                Spacer()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PressurePointsView: View {
    // Expanded seed deck
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

    @Environment(\.modelContext) private var context
    @Query(sort: \PressureSlip.trigger) private var slips: [PressureSlip]

    // UI
    @State private var query = ""
    @State private var showAdd = false
    @State private var showFlash = false
    @State private var flashItems: [PressureSlip] = []
    @State private var startIndex: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header + Add button
                    HStack {
                        Text("Everyday Pressures")
                            .font(.title3).bold()
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search…", text: $query)
                    }
                    .padding(12)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Your saved pressures (if any)
                    if !filteredYours.isEmpty {
                        Text("Yours")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(filteredYours) { p in
                                MiniPressureCard(title: p.trigger)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            context.delete(p)
                                            try? context.save()
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .onTapGesture {
                                        openFlash(startingAt: p.trigger)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Starter deck
                    Text("Starter deck")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(filteredStarter, id: \.0) { item in
                            MiniPressureCard(title: item.0)
                                .onTapGesture { openFlash(startingAt: item.0) }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Everyday Pressures")
            .task { seedIfNeeded() }
            .sheet(isPresented: $showAdd) {
                AddPressureSlipSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFlash) {
                PressureFlashView(items: flashItems, startIndex: startIndex)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Filtering / Seed / Open Flash

    private var filteredYours: [PressureSlip] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return slips }
        return slips.filter { $0.trigger.lowercased().contains(q) || $0.slip.lowercased().contains(q) }
    }

    private var filteredStarter: [(String,String)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return defaultItems }
        return defaultItems.filter { $0.0.lowercased().contains(q) || $0.1.lowercased().contains(q) }
    }

    private func seedIfNeeded() {
        guard slips.isEmpty else { return }
        defaultItems.forEach {
            context.insert(PressureSlip(trigger: $0.0, slip: $0.1))
        }
        try? context.save()
    }

    private func openFlash(startingAt title: String) {
        // Merge (user > starter) without duplicates
        // Build a unified array of PressureSlip so the flash view is simple
        var byTitle: [String: PressureSlip] = Dictionary(uniqueKeysWithValues: slips.map { ($0.trigger, $0) })
        for (t, s) in defaultItems where byTitle[t] == nil {
            byTitle[t] = PressureSlip(trigger: t, slip: s)
        }
        let merged = Array(byTitle.values)
            .sorted { $0.trigger.localizedCaseInsensitiveCompare($1.trigger) == .orderedAscending }

        let idx = merged.firstIndex(where: { $0.trigger == title }) ?? 0
        flashItems = merged
        startIndex = idx
        showFlash = true
    }
}

@Model
final class PressureSlip {
    @Attribute(.unique) var id: String
    var trigger: String
    var slip: String

    init(trigger: String, slip: String) {
        self.id = UUID().uuidString
        self.trigger = trigger
        self.slip = slip
    }
}

private struct MiniPressureCard: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(UIColor.separator), lineWidth: 1)
        )
    }
}
