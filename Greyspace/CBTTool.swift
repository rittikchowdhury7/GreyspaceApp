//
//  CBTTool.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

// CBTTool.swift — Guided, destigmatized thought record

import SwiftUI
import SwiftData

// MARK: - Thought Builder (5-step guided flow)
struct ThoughtBuilderWizard: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Intro
    @State private var showIntro = true

    // Steps
    @State private var step: Int = 1
    private let totalSteps = 5

    // Inputs
    @State private var rawThought: String = ""
    @State private var feeling: Feeling? = nil
    @State private var whyChoice: WhyOption? = nil
    @State private var isWritingCustomWhy = false
    @State private var customWhy: String = ""
    @State private var whyFreeform: String = ""
    
    // WHY (AI) state
    @State private var aiWhyIdeas: [String] = []
    @State private var aiWhyLoading = false
    @State private var aiWhyError: String? = nil
    @State private var aiReframeIdeas: [String] = []
    @State private var aiReframeLoading: Bool = false
    @State private var aiReframeAnimateIntro = false


    // Reframe
    @State private var suggestions: [String] = []
    @State private var chosenReframe: String = ""
    @State private var isSaving = false

    // Polaroid moment
    @State private var showPolaroid = false
    @State private var polaroidBounce = false

    // Optional AI (uses a safe local fallback by default)
    
    // Single source of truth for the Why answer (chip OR custom/AI text)
    private var whyReason: String {
        let fromChoice = whyChoice?.title ?? ""
        return !customWhy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? customWhy
            : fromChoice
    }
    
    private var canAdvanceWhy: Bool { !whyReason.isEmpty }

    // Can the user go forward from the current step?
    private var canAdvanceCurrentStep: Bool {
        switch step {
        case 1: // Thought
            return !rawThought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: // Feeling (must be selected)
            return feeling != nil
        case 3: // Why (chip OR custom/AI)
            return !whyReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    // Optional: prevent advancing while AI results are loading
    private var isAILoading: Bool {
        (step == 3 && aiWhyLoading) || (step == 4 && aiReframeLoading)
    }


    private let aiService = AIReframeService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                StepHeader2(title: "Thought Builder", step: step, total: totalSteps)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        currentStepView
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }

                toolbar
            }
            .navigationTitle("Thought Helper")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: step) { _ in
                if step == 4 { refreshSuggestions() }
            }
            .sheet(isPresented: $showPolaroid) {
                PolaroidMomentView(
                    originalThought: rawThought,
                    reframe: chosenReframe,
                    onDone: { showPolaroid = false; dismiss() },
                    startFlipped: true,
                    showTapHint: false
                )
                .task { await saveRecordAndClose() }    // ✅ use a View modifier, not a bare Task
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Steps
    @ViewBuilder private var currentStepView: some View {
        switch step {
        case 1: captureThoughtStep
        case 2: feelingStep
        case 3: whyStep
        case 4:
            ReframeStepView(
                suggestions: $suggestions,
                aiSuggestions: $aiReframeIdeas,        // ← NEW
                chosenReframe: $chosenReframe,
                aiLoading: aiReframeLoading,
                animateAIText: aiReframeAnimateIntro,
                onMoreIdeas: {
                    // fetch via your service, e.g.:
                    Task {
                        let more = try? await aiService.suggest(
                            for: rawThought,
                            feeling: feeling?.title ?? "",
                            why: (isWritingCustomWhy ? customWhy : whyChoice?.title) ?? ""
                        )
                        await MainActor.run {
                            aiReframeIdeas = more ?? []
                            aiReframeAnimateIntro = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                aiReframeAnimateIntro = false
                            }
                        }
                    }
                },
                onWriteOwn: { chosenReframe = "" }
            )
        case 5: reviewStep
        default: captureThoughtStep
        }
    }
    
    // Mark one extra binding: aiSuggestions
    private struct ReframeStepView: View {
        @Binding var suggestions: [String]
        @Binding var aiSuggestions: [String]          // NEW
        @Binding var chosenReframe: String
        var aiLoading: Bool                           // NEW
        var animateAIText: Bool                       // NEW (one-time typewriter)
        var onMoreIdeas: () -> Void
        var onWriteOwn: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                Text("Try a softer reframe").font(.title3).bold()
                Text("You’re not fixing your thought—just softening it.")
                    .font(.footnote).foregroundStyle(.secondary)

                if suggestions.isEmpty && aiSuggestions.isEmpty && !aiLoading {
                    Text("We’ll suggest options once you’ve added a thought and a feeling.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                // Non-AI suggestions
                if !suggestions.isEmpty {
                    Text("Suggestions")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ReframeSuggestionsList(
                        items: suggestions.map { SuggestionItem(text: $0, isAI: false) },
                        chosenReframe: $chosenReframe,
                        animateAIText: false
                    )
                }

                // AI suggestions + badge + optional typewriter
                if aiLoading {
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(.circular)
                        Text("Getting ideas…")
                    }
                    .padding(.vertical, 4)
                } else if !aiSuggestions.isEmpty {
                    HStack(spacing: 6) {
                        Text("Suggestions from AI")
                            .font(.subheadline).foregroundStyle(.secondary)
                        AIBadge()
                    }
                    ReframeSuggestionsList(
                        items: aiSuggestions.map { SuggestionItem(text: $0, isAI: true) },
                        chosenReframe: $chosenReframe,
                        animateAIText: animateAIText   // ← only true right after fetch
                    )
                    Text("Tips are AI-generated. Pick what fits you.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                HStack {
                    Button(action: onMoreIdeas) {
                        if aiLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Getting ideas…")
                            }
                        } else {
                            Label("More ideas", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(aiLoading)

                    Spacer()

                    Button(action: onWriteOwn) {
                        Label("Write my own", systemImage: "square.and.pencil")
                    }
                }

                if chosenReframe.isEmpty {
                    TextField("Write your own reframe…", text: $chosenReframe, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 0)
        }
    }
    private var captureThoughtStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What’s on your mind?").font(.title3).bold()
            Text("Anything is okay to write. This is just for you.").font(.footnote).foregroundStyle(.secondary)
            TextEditor(text: $rawThought)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                .padding(.top, 4)
            HStack {
                Text("\(rawThought.count)/300").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private var feelingStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What feeling is underneath this?").font(.title3).bold()
            Text("There’s no right answer. Tap whatever feels closest.").font(.footnote).foregroundStyle(.secondary)

            // Feeling step chips (iOS 16+ FlowLayout)
            Flow(spacing: 8, rowSpacing: 8) {
                ForEach(Feeling.allCases) { item in
                    let isSelected = (feeling == item)
                    Button {
                        feeling = isSelected ? nil : item
                    } label: {
                        Chip(title: item.title, selected: isSelected, emoji: item.emoji,)
                            .padding(4) // small padding so chips don't touch
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Why Step
    // MARK: - Why Step (general + write own + AI)
    private var whyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2 of \(totalSteps)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Why do you think this thought showed up?")
                .font(.title3).bold()

            // Built-in general reasons (chips)
            Flow(spacing: 8, rowSpacing: 8) {
                ForEach(WhyOption.allCases) { option in
                    let isSelected = (whyChoice == option)
                    Button {
                        // Toggle chip; clear custom text if choosing a chip
                        if isSelected { whyChoice = nil } else { whyChoice = option }
                        isWritingCustomWhy = false
                        customWhy = ""
                    } label: {
                        Chip(title: option.title, selected: isSelected)
                    }
                    .buttonStyle(.plain)
                }

                // "Write my own" chip
                Button {
                    isWritingCustomWhy.toggle()
                    if isWritingCustomWhy { whyChoice = nil }
                } label: {
                    Chip(title: "Write my own", selected: isWritingCustomWhy)
                }
                .buttonStyle(.plain)
            }

            // Inline text field when writing custom
            if isWritingCustomWhy {
                TextField("Type your reason here…", text: $customWhy)
                    .textFieldStyle(.roundedBorder)
            }

            // AI button + status
            HStack(spacing: 12) {
                Button {
                    fetchAIWhyIdeas()
                } label: {
                    if aiWhyLoading {
                        ProgressView().progressViewStyle(.circular)
                            .padding(.trailing, 6)
                        Text("Getting ideas…")
                    } else {
                        Label("Ask AI for ideas", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(aiWhyLoading)

                if let err = aiWhyError {
                    Text(err).font(.footnote).foregroundStyle(.secondary)
                }
            }

            // Render AI suggestions as additional chips you can tap
            if !aiWhyIdeas.isEmpty {
                Text("Suggestions from AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Flow(spacing: 8, rowSpacing: 8) {
                    ForEach(aiWhyIdeas, id: \.self) { idea in
                        let isSelected = (isWritingCustomWhy && customWhy == idea)
                        Button {
                            isWritingCustomWhy = true
                            customWhy = idea
                            whyChoice = nil
                        } label: {
                            Chip(title: idea, selected: isSelected, ai: true, animated: true)
                                .padding(2) // breathing room
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("AI suggestion")
                    }
                }
            }
        }
    }
    private struct SuggestionItem: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let isAI: Bool
    }

    private struct ReframeSuggestionsList: View {
        let items: [SuggestionItem]
        @Binding var chosenReframe: String
        var animateAIText: Bool = false

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items) { item in
                    let selected = (chosenReframe == item.text)
                    Button {
                        chosenReframe = item.text
                    } label: {
                        SuggestionRow(
                            text: item.text,
                            selected: selected,
                            isAI: item.isAI,
                            animated: animateAIText && item.isAI // animate only on first show
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private struct SuggestionRow: View {
        let text: String
        let selected: Bool
        let isAI: Bool
        var animated: Bool = false

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 6) {
                    if animated {
                        TypewriterText(fullText: text, speed: 0.015)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if isAI { AIBadge() }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator), lineWidth: 1))
        }
    }

 

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Greyspace moment").font(.title3).bold()
            Text("A balanced thought to carry with you.").font(.footnote).foregroundStyle(.secondary)

            PolaroidCard(original: rawThought, reframe: chosenReframe.isEmpty ? "Your softer thought will appear here." : chosenReframe)
                .frame(height: 260)
                .opacity(chosenReframe.isEmpty ? 0.65 : 1.0)
                .scaleEffect(polaroidBounce ? 1.02 : 1)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.4)) {
                        polaroidBounce = true
                    }
                }

            Text("You can always edit or add to this later.").font(.footnote).foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Back
            Button("Back") {
                if step == 1 { dismiss() }
                else {
                    withAnimation(.easeInOut) { step -= 1 }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
                    .disabled(step == 1)

                    Spacer()

                    // Next / Save
                    if step < totalSteps {
                        Button {
                            stepForward()
                        } label: {
                            // Only show spinner on steps that actually use AI (adjust if needed)
                            if isAILoading && (step == 3 || step == 4) {
                                HStack(spacing: 8) { ProgressView(); Text("Working…") }
                            } else {
                                Text("Next")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        // Keep your existing gating
                        .disabled(!canAdvanceCurrentStep || (isAILoading && (step == 3 || step == 4)))
                    } else {
                        Button {
                            guard !chosenReframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                return
                            }
                            showPolaroid = true
                        } label: {
                            Text(isSaving ? "Saving…" : "Save")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(chosenReframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    // MARK: - Logic
    private var canAdvance: Bool {
        switch step {
        case 1: return !rawThought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return feeling != nil
        case 3: return whyChoice != nil || !whyFreeform.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: return !chosenReframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return true
        }
    }

    private func stepForward() {
        guard canAdvanceCurrentStep && !isAILoading else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        withAnimation(.easeInOut) {
            step = min(step + 1, totalSteps)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func refreshSuggestions() {
        let f = feeling?.title ?? ""
        let why = (whyChoice?.title ?? "").nilIfEmpty ?? whyFreeform
        suggestions = StarterReframeEngine.propose(
            thought: rawThought,
            feeling: f,
            why: why
        )
        if chosenReframe.isEmpty, let first = suggestions.first {
            chosenReframe = first
        }
    }
    
    private func fetchAIWhyIdeas() {
        guard !aiWhyLoading else { return }
        aiWhyError = nil
        aiWhyLoading = true

        Task {
            let ideas = await aiService.whySuggestions(
                for: rawThought,
                feeling: feeling?.title,   // or feeling?.rawValue depending on your enum
                limit: 8
            )
            await MainActor.run {
                aiWhyIdeas = ideas
                aiWhyLoading = false
                if ideas.isEmpty {
                    aiWhyError = "AI is unavailable right now — try again later."
                }
            }
        }
    }

    private func aiAssist() async {
        do {
            let f = feeling?.title ?? ""
            let w = (whyChoice?.title ?? "").nilIfEmpty ?? whyFreeform
            let more = try await aiService.suggestReframes(thought: rawThought, feeling: f, why: w, limit: 5)
            // De-dup and append
            let newOnes = more.filter { !suggestions.contains($0) }
            suggestions.append(contentsOf: newOnes.prefix(3))
            if chosenReframe.isEmpty, let first = suggestions.first { chosenReframe = first }
        } catch {
            // fallback: keep suggestions
        }
    }

    private func saveRecordAndClose() async {
        guard !chosenReframe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true
        let record = ThoughtRecord(
            date: .now,
            situation: (whyChoice?.title ?? "").nilIfEmpty ?? whyFreeform,           // <-- reuse 'situation' as "why"
            automaticThought: rawThought,
            emotionLabel: feeling?.title ?? "",
            intensity: 0,                      // you can add a slider later if you want
            distortions: [],
            evidenceFor: "",
            evidenceAgainst: "",
            reframe: chosenReframe,
                         // not used in this flow
        )
        context.insert(record)
        try? context.save()
        isSaving = false
    }
}

// MARK: - Chips & helpers


private struct Chip: View {
    let title: String
    let selected: Bool
    var emoji: String? = nil
    var ai: Bool = false          // show AI badge
    var animated: Bool = false    // typewriter effect

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 8) {
                if let emoji { Text(emoji) }
                if animated {
                    TypewriterText(fullText: title, speed: 0.015)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                } else {
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08),
                        in: Capsule())
            .overlay(
                Capsule().stroke(selected ? Color.accentColor.opacity(0.6) : Color(UIColor.separator),
                                 lineWidth: 1)
            )
            .foregroundStyle(selected ? Color.accentColor : .primary)
            .accessibilityElement(children: .combine)
            // AI badge
            if ai {
                AIBadge()
                    .offset(x: 6, y: -6)
            }
        }
    }
}

private struct FlowChips<Item: Identifiable & Hashable, Content: View>: View {
    @Binding var selection: Item?
    let items: [Item]
    let content: (Item, Bool) -> Content

    var body: some View {
        FlexibleView(data: items, spacing: 8, alignment: .leading) { item in
            let selected = selection == item
            Button {
                selection = selected ? nil : item
            } label: {
                content(item, selected)
            }
            .buttonStyle(.plain)
        }
    }
}

// Wrap layout for chips
private struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data, spacing: CGFloat, alignment: HorizontalAlignment, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                ForEach(Array(data.enumerated()), id: \.1.id) { _, element in
                    content(element)
                        .padding(.all, 4)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geo.size.width) {
                                width = 0
                                height -= d.height + spacing
                            }
                            let result = width
                            if element.id == data.first?.id { width = 0 }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if element.id == data.first?.id { height = 0 }
                            return result
                        }
                        .background(
                            GeometryReader { inner in
                                Color.clear.onAppear {
                                    width += inner.size.width + spacing
                                }
                            }
                        )
                }
            }
        }
        .frame(minHeight: 10)
    }
}

// MARK: - Enums (feelings & why options)

enum Feeling: String, CaseIterable, Identifiable, Hashable {
    case anger, stress, boredom, anxiety, jealousy, sadness, guilt, shame, loneliness, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .anger: return "Anger"
        case .stress: return "Stress"
        case .boredom: return "Boredom"
        case .anxiety: return "Anxiety"
        case .jealousy: return "Jealousy"
        case .sadness: return "Sadness"
        case .guilt: return "Guilt"
        case .shame: return "Shame"
        case .loneliness: return "Loneliness"
        case .other: return "Other"
        }
    }
    var emoji: String {
        switch self {
        case .anger: return "😤"
        case .stress: return "😮‍💨"
        case .boredom: return "🥱"
        case .anxiety: return "😰"
        case .jealousy: return "🫥"
        case .sadness: return "😔"
        case .guilt: return "😞"
        case .shame: return "🙈"
        case .loneliness: return "🥲"
        case .other: return "🤍"
        }
    }
}

enum WhyOption: String, CaseIterable, Identifiable {
    case fearOfJudgment = "Fear of judgment"
    case wantingControl = "Wanting control"
    case seekingAcceptance = "Seeking acceptance"
    case protectingSelf = "Protecting myself"
    case feelingGuilty = "Feeling guilty"
    case seekingComfort = "Seeking comfort"
    case overwhelmed = "Feeling overwhelmed"

    var id: String { rawValue }
    var title: String { rawValue }
}

// Add to your view state


// MARK: - Starter reframe engine

enum StarterReframeEngine {
    static func propose(thought: String, feeling: String, why: String) -> [String] {
        guard !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var out: [String] = []

        // Global softeners
        out.append("I’m looking for connection; I can be real without putting others down.")
        out.append("This urge is a signal, not a definition of me. I can choose kindness next.")
        out.append("I can share how I feel instead of sharing about someone else.")

        if feeling.localizedCaseInsensitiveContains("anger") {
            out.append("My anger wants release; I can cool it with a breath and speak honestly later.")
        }
        if feeling.localizedCaseInsensitiveContains("anxiety") || feeling.localizedCaseInsensitiveContains("stress") {
            out.append("I’m stressed; a pause may help me say what I actually need.")
        }
        if why.localizedCaseInsensitiveContains("fit") || why.localizedCaseInsensitiveContains("connected") {
            out.append("I want to belong; I can build closeness by being genuine.")
        }
        if why.localizedCaseInsensitiveContains("insecure") {
            out.append("When I’m insecure, I can ask for reassurance or take space to ground myself.")
        }
        if why.localizedCaseInsensitiveContains("bored") || feeling.localizedCaseInsensitiveContains("bored") {
            out.append("I’m restless; choosing a small, nourishing action will feel better than gossip.")
        }
        // De-dup and trim to top 5
        return Array(NSOrderedSet(array: out)) as? [String] ?? out.prefix(5).map { $0 }
    }
}

// MARK: - AI hook (safe default)

protocol ReframeSuggester {
    func suggest(for thought: String, feeling: String, why: String) async throws -> [String]
}

// Local fallback that just expands with StarterReframeEngine
struct DefaultLocalReframer: ReframeSuggester {
    func suggest(for thought: String, feeling: String, why: String) async throws -> [String] {
        StarterReframeEngine.propose(thought: thought, feeling: feeling, why: why)
    }
}

// If you already have AIReframeService, you can conform it here:
// extension AIReframeService: ReframeSuggester {
//     func suggest(for thought: String, feeling: String, why: String) async throws -> [String] {
//         let prompt = "\(thought)\nFeeling:\(feeling)\nWhy:\(why)"
//         let text = try await reframe(thought: prompt) // your existing API call
//         return [text]
//     }
// }

// MARK: - Small helpers
private struct AIBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles").imageScale(.small)
            Text("AI").font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel("AI suggestion")
    }
}



private struct TypewriterText: View {
    let fullText: String
    var speed: Double = 0.02
    @State private var shown = ""

    var body: some View {
        Text(shown)
            .onAppear {
                shown = ""
                Task {
                    for (i, ch) in fullText.enumerated() {
                        try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
                        shown.append(ch)
                        if i % 5 == 0 { await Task.yield() }
                    }
                }
            }
    }
}

private struct StepHeader2: View {
    let title: String
    let step: Int
    let total: Int
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text("Step \(step) of \(total)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView(value: Double(step), total: Double(total))
                .frame(width: 120)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let s = trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }
}
