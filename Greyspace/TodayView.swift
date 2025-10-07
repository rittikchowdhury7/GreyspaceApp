//
//  TodayView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI
import SwiftData
import PhotosUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: RootView.Tab

    // Mode: home card vs. wizard
    enum Mode { case home, wizard }
    @State private var mode: Mode = .home

    // Wizard state
    @State private var step: Int = 1
    private let totalSteps: Int = 6

    // Form state
    @State private var mood: Int = 3
    @State private var anxiety: Int = 3
    @State private var gratitude: [String] = ["", "", ""]
    @State private var notes: String = ""
    @State private var didMindfulness: Bool = false
    @AppStorage("intro.skip.checkin") private var skipCheckInIntro = false
    @State private var showCheckInIntro = false

    // ✅ These should be local state, not @Binding
    @State private var draft: JournalEntry = JournalEntry()                 // holds photos: [ImageAttachment]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var justPickedThumbs: [UIImage] = []

    // Last entry for the home summary
    @Query(sort: \JournalEntry.date, order: .reverse, animation: .default)
    var entries: [JournalEntry]

    @State private var showCBT = false

    var body: some View {
        NavigationStack {
            Group {
                if mode == .home { homeCard } else { wizard }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedTab) { newValue in
                if newValue == .today {
                    withAnimation { resetToHome() }
                }
            }
            .task {
                await NotificationService.requestAuthorization()
                NotificationService.scheduleDaily(reminder: .morning, id: "reminder.morning")
                NotificationService.scheduleDaily(reminder: .evening, id: "reminder.evening")
            }
        }
    }

    // MARK: - HOME

    private var homeCard: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                SurfaceCard {
                    HStack(spacing: DS.Spacing.lg) {
                        if let _ = UIImage(named: "GreyspaceLogo") {
                            Image("GreyspaceLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                        } else {
                            Image(systemName: "circle.lefthalf.filled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .foregroundStyle(DS.Color.accent)
                                .padding(DS.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                                        .fill(DS.Color.accent.opacity(0.12))
                                )
                        }
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text("Greyspace")
                                .font(DS.Typography.title())
                                .foregroundStyle(DS.Color.onSurface)
                            Text("Where your thoughts don’t have to be black or white.")
                                .font(DS.Typography.body())
                                .foregroundStyle(DS.Color.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        if let last = entries.first {
                            Text("Last check-in")
                                .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                            HStack {
                                Text(last.date, style: .date)
                            Text("•")
                            Text(last.date, style: .time)
                            Spacer()
                            Text("Mood \(last.mood)/5 · A \(last.anxiety)/10")
                                .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                        }
                        if !last.gratitude.isEmpty {
                            Text("Gratitude: " + last.gratitude.joined(separator: ", "))
                                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
                                .lineLimit(1)
                        } else if !last.notes.isEmpty {
                            Text("“\(last.notes)”")
                                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No entries yet — a 60-second snapshot is a great first step.")
                            .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                    }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // CTA
                // In TodayView, replace your Start Check-In button with:
                Button {
                    if skipCheckInIntro {
                        // jump straight to wizard
                        draft = JournalEntry()
                        withAnimation { mode = .wizard }
                    } else {
                        showCheckInIntro = true
                    }
                } label: {
                    Text("Start Check-In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DS.Spacing.lg)
                .sheet(isPresented: $showCheckInIntro) {
                    CheckInIntroSheet {
                        // onStart → actually begin the wizard
                        draft = JournalEntry()
                        withAnimation { mode = .wizard }
                        showCheckInIntro = false
                    }
                }

                // Quick tools
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text("Quick tools")
                        .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                    let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: DS.Spacing.md)]
                    LazyVGrid(columns: columns, spacing: DS.Spacing.md) {
                        NavigationLink { MindfulnessIntroContainer() } label: {
                            toolCard(title: "One-breath reset", icon: "wind")
                        }.buttonStyle(.plain)

                        Button { showCBT = true } label: {
                            toolCard(title: "Thought helper", icon: "lightbulb")
                        }.buttonStyle(.plain)

                        NavigationLink { PressureIntroContainer() } label: {
                            toolCard(title: "Everyday Pressures", icon: "exclamationmark.bubble")
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, DS.Spacing.lg)

                    VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                        Text("This month")
                            .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
                        JournalCalendarView(entries: entries)
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
            }
            .padding(.vertical, DS.Spacing.xl)
        }
        .sheet(isPresented: $showCBT) { ThoughtHelperContainer() }
    }

    private func toolCard(title: String, icon: String) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .imageScale(.large)
                    .foregroundStyle(DS.Color.accent)
                    .padding(DS.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .fill(DS.Color.accent.opacity(0.12))
                    )
                Text(title)
                    .font(DS.Typography.heading())
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - WIZARD

    private var wizard: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                StepHeader(title: "Today Check-In", step: step, total: totalSteps)

                currentStepView
                    .animation(.easeInOut, value: step)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.lg)
            }
            .padding(.bottom, 120)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Back") {
                    if step == 1 { withAnimation { mode = .home } }
                    else { step -= 1 }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(step == 1 && mode == .wizard)

                Spacer()

                if canSkipCurrentStep {
                    Button("Skip") { skipCurrentStep() }
                        .buttonStyle(SecondaryButtonStyle())
                }

                Button(step == totalSteps ? "Save" : "Next") {
                    if step < totalSteps { step += 1 } else { saveEntry() }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 1: moodStep
        case 2: anxietyStep
        case 3: gratitudeStep
        case 4: photosStep
        case 5: notesStep
        case 6: mindfulnessStep
        default: reviewStep
        }
    }

    // MARK: Steps

    private var moodStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 1 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("How’s your mood right now?").font(DS.Typography.heading()).bold()
            Picker("Mood", selection: $mood) {
                ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            Text("Pick a number that feels right in this moment.")
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
        }
    }

    private var anxietyStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 2 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("How much anxiety is present?").font(DS.Typography.heading()).bold()
            Slider(value: Binding(get: { Double(anxiety) }, set: { anxiety = Int($0) }),
                   in: 0...10, step: 1)
            HStack { Text("0"); Spacer(); Text("10") }
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
            Text("Current anxiety: \(anxiety) / 10").font(DS.Typography.heading())
        }
    }

    private var gratitudeStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 3 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("One small thing that went right?").font(DS.Typography.heading()).bold()
            ForEach(gratitude.indices, id: \.self) { idx in
                TextField("I’m grateful for… (optional)", text: Binding(
                    get: { gratitude[idx] }, set: { gratitude[idx] = $0 }))
                .textFieldStyle(.roundedBorder)
            }
            Text("You can leave these blank and tap Skip.")
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
        }
    }

    // ✅ New Photos step (local-only, using draft.photos: [ImageAttachment])
    private var photosStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Add any photos that capture your day. They stay on your device.")
                .font(DS.Typography.body()).foregroundStyle(DS.Color.muted)

            PhotosPicker(selection: $pickerItems,
                         maxSelectionCount: 6,
                         matching: .images,
                         photoLibrary: .shared()) {
                Label("Add photos", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: pickerItems) { _ in
                Task { await importPickedPhotos() }
            }

            if draft.photos.isEmpty && justPickedThumbs.isEmpty {
                Text("No photos yet").foregroundStyle(DS.Color.muted)
            } else {
                let columns = [GridItem(.adaptive(minimum: 90), spacing: DS.Spacing.sm)]
                LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                    ForEach(draft.photos) { photo in
                        if let img = AttachmentStore.load(filename: photo.filename) {
                            Thumb(img: img) {
                                AttachmentStore.delete(filename: photo.filename)
                                draft.photos.removeAll { $0.id == photo.id }
                            }
                        }
                    }
                    // freshly picked (not yet reloaded from disk; optional)
                    ForEach(justPickedThumbs.indices, id: \.self) { i in
                        Thumb(img: justPickedThumbs[i], onDelete: nil)
                    }
                }
            }
        }
    }

    private func importPickedPhotos() async {
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                do {
                    let filename = try AttachmentStore.save(image: ui)
                    draft.photos.append(ImageAttachment(filename: filename))   // ⬅️ your model
                    justPickedThumbs.append(ui)
                } catch {
                    print("Save failed: \(error)")
                }
            }
        }
        pickerItems.removeAll()
    }

    private struct Thumb: View {
        let img: UIImage
        var onDelete: (() -> Void)?
        var body: some View {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))

                if let onDelete {
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(DS.Color.onSurface.opacity(0.95))
                            .background(Circle().fill(DS.Color.background.opacity(0.35)))
                    }
                    .offset(x: -4, y: 4)
                }
            }
        }
    }

    private var notesStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 5 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("Anything on your mind?").font(DS.Typography.heading()).bold()
            TextEditor(text: $notes)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.Color.muted.opacity(0.2)))
            Text("Optional. Jot a sentence, or Skip.")
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
        }
    }

    private var mindfulnessStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 6 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("One-breath reset (10 seconds)").font(DS.Typography.heading()).bold()
            BreathingCircle(active: $didMindfulness).frame(height: 220)
            Toggle("I did a breath", isOn: $didMindfulness)
            Text("Inhale as the circle expands. Exhale as it shrinks. Do 1–3 cycles.")
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("Step 6 of \(totalSteps)").font(DS.Typography.body()).foregroundStyle(DS.Color.muted)
            Text("Review").font(DS.Typography.heading()).bold()
            SummaryRow(label: "Mood", value: "\(mood) / 5")
            SummaryRow(label: "Anxiety", value: "\(anxiety) / 10")
            if !cleanGratitude.isEmpty {
                SummaryRow(label: "Gratitude", value: cleanGratitude.joined(separator: ", "))
            }
            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                SummaryRow(label: "Notes", value: "“\(notes.trimmingCharacters(in: .whitespacesAndNewlines))”")
            }
            if !draft.photos.isEmpty {
                SummaryRow(label: "Photos", value: "\(draft.photos.count)")
            }
            SummaryRow(label: "Mindfulness", value: didMindfulness ? "✓" : "—")
            Text("Tap **Save** to finish. If anxiety is high or mood low, we’ll offer a quick thought helper next.")
                .font(DS.Typography.caption()).foregroundStyle(DS.Color.muted).padding(.top, DS.Spacing.sm)
        }
    }

    // MARK: helpers

    private var cleanGratitude: [String] {
        gratitude.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private var canSkipCurrentStep: Bool {
        // photos/notes/mindfulness are optional
        step == 3 || step == 4 || step == 5
    }

    private func skipCurrentStep() {
        switch step {
        case 3:
            gratitude = ["", "", ""]
        case 4:
            // photos step → just clear any pending picks (optional)
            pickerItems.removeAll()
            justPickedThumbs.removeAll()
        case 5:
            didMindfulness = false
        default: break
        }
        step = min(step + 1, totalSteps)
    }

    private func resetToHome() {
        mode = .home
        step = 1
        mood = 3
        anxiety = 3
        gratitude = ["", "", ""]
        notes = ""
        didMindfulness = false
        pickerItems.removeAll()
        justPickedThumbs.removeAll()
        draft = JournalEntry()
    }

    private func saveEntry() {
        let entry = JournalEntry(
            date: .now,
            mood: mood,
            anxiety: anxiety,
            gratitude: cleanGratitude,
            photos: draft.photos, // ⬅️ carry over the attachments you added
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: [],
            didMindfulness: didMindfulness
        )
        context.insert(entry)
        do { try context.save() } catch { print("Save error: \(error)") }

        let decision = PromptEngine.decide(mood: mood, anxiety: anxiety)
        if decision.shouldSuggestCBT { showCBT = true }

        // reset wizard state
        resetToHome()

        // jump to History (or remove if you prefer to stay on Today)
        withAnimation { selectedTab = .history }
    }
}
