//
//  SupportView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


// SettingsView.swift
import SwiftUI
import LocalAuthentication
import SwiftData

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \ThoughtRecord.date, order: .reverse) private var thoughts: [ThoughtRecord]
    @Query(sort: \PressureSlip.trigger) private var pressures: [PressureSlip]

    // Language
    @AppStorage(AppLanguage.storageKey) private var appLanguage: String = AppLanguage.defaultCode // "system","en","hi","fil","zh-Hans"

    // Intros (skip flags used across the app)
    @AppStorage("intro.skip.checkin")      private var skipCheckInIntro = false
    @AppStorage("intro.skip.thoughtHelper")private var skipThoughtIntro = false
    @AppStorage("intro.skip.pressures")    private var skipPressuresIntro = false
    @AppStorage("intro.skip.mindfulness")  private var skipMindfulIntro = false

    // Preferences
    @AppStorage("pref.haptics")       private var hapticsEnabled = true
    @AppStorage("pref.analytics.optin") private var analyticsOptIn = false

    // Lock
    @AppStorage("pref.lock.enabled")  private var lockEnabled = false
    @State private var lockAuthError: String?
    @State private var showingClearConfirm = false
    @State private var showingExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: – General
                Section(header: Text("General")) {
                    Picker("Language", selection: $appLanguage) {
                        ForEach(AppLanguage.all) { lang in
                            Text(lang.localizedKey).tag(lang.code)
                        }
                    }
                    .onChange(of: appLanguage) { newValue in
                        AppLanguage.applySelection(newValue)
                        NotificationCenter.default.post(name: .appLanguageDidChange,
                                                        object: AppLanguage.resolved(for: newValue))
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }

                    Toggle("Haptics", isOn: $hapticsEnabled)
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Toggle("Share anonymous usage", isOn: $analyticsOptIn)
                            .tint(DS.Color.accent)

                        Text("Helps improve Greyspace; never includes your notes or photos.")
                            .font(DS.Typography.caption())
                            .foregroundStyle(DS.Color.muted)
                    }
                }

                // MARK: – Privacy & Security
                Section(header: Text("Privacy & Security"),
                        footer: Text("Adds a Face ID / Touch ID prompt when opening the app.")) {
                    Toggle("Lock with Face ID / Touch ID", isOn: Binding(
                        get: { lockEnabled },
                        set: { newVal in
                            if newVal {
                                authBiometrics { success in
                                    if success { lockEnabled = true }
                                }
                            } else {
                                lockEnabled = false
                            }
                        }
                    ))
                }

                // MARK: – Intros
                Section(header: Text("Feature Intros"),
                        footer: Text("Reset these if you want to see the short intros again.")) {
                    Toggle("Skip Check-In intro", isOn: $skipCheckInIntro)
                    Toggle("Skip Thought Helper intro", isOn: $skipThoughtIntro)
                    Toggle("Skip Everyday Pressures intro", isOn: $skipPressuresIntro)
                    Toggle("Skip One-Breath Reset intro", isOn: $skipMindfulIntro)

                    Button("Reset all intros") {
                        skipCheckInIntro = false
                        skipThoughtIntro = false
                        skipPressuresIntro = false
                        skipMindfulIntro = false
                    }
                }

                // MARK: – Data
                Section(header: Text("Your Data"),
                        footer: Text("Check-ins, reframes, and pressures are stored locally on your device.")) {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export as text", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        do {
                            try context.delete(model: JournalEntry.self)
                            try context.delete(model: ThoughtRecord.self)
                            try context.save()
                        } catch {
                            print("Failed to wipe data: \(error)")
                        }
                    } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                }

                // MARK: – About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersionString())
                            .foregroundStyle(DS.Color.muted)
                    }
                    Button {
                        // Replace with your App Store URL
                        if let url = URL(string: "https://apps.apple.com") { openURL(url) }
                    } label: {
                        Label("Rate Greyspace", systemImage: "star")
                    }
                    Button {
                        // Replace with your Privacy Policy URL
                        if let url = URL(string: "https://example.com/privacy") { openURL(url) }
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.Color.background)
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all local data?",
                isPresented: $showingClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingExportSheet) {
                let txt = exportAllText()
                ShareSheet(items: [txt])
            }
        }
    }

    // MARK: – Helpers

    private func appVersionString() -> String {
        let v = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "–"
        let b = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "–"
        return "\(v) (\(b))"
    }

    private func authBiometrics(completion: @escaping (Bool) -> Void) {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            lockAuthError = error?.localizedDescription ?? "Biometrics not available"
            completion(false)
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Enable app lock") { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    private func exportAllText() -> String {
        var lines: [String] = []
        let language = Localization.currentLanguage()
        lines.append(Localization.string("export.header", fallback: "— Greyspace Export —\n", language: language))

        // Journal entries
        lines.append(Localization.string("export.section.checkins", fallback: "== Check-Ins ==", language: language))
        for e in entries {
            let dateLine = String(format: Localization.string("export.entry.date", fallback: "• %@", language: language), e.date.formatted(date: .complete, time: .shortened))
            lines.append(dateLine)
            let moodLine = String(format: Localization.string("export.entry.mood", fallback: "  Mood %d/5 | Anxiety %d/10", language: language), e.mood, e.anxiety)
            lines.append(moodLine)
            if !e.gratitude.isEmpty {
                let value = e.gratitude.joined(separator: ", ")
                let text = String(format: Localization.string("export.entry.gratitude", fallback: "  Gratitude: %@", language: language), value)
                lines.append(text)
            }
            if !e.notes.isEmpty {
                let text = String(format: Localization.string("export.entry.notes", fallback: "  Notes: %@", language: language), e.notes)
                lines.append(text)
            }
            if e.didMindfulness {
                lines.append(Localization.string("export.entry.mindfulness", fallback: "  Mindfulness: ✓", language: language))
            }
            if !e.photos.isEmpty {
                let text = String(format: Localization.string("export.entry.photos", fallback: "  Photos: %d (stored locally)", language: language), e.photos.count)
                lines.append(text)
            }
            lines.append("")
        }

        // Thought records (reframes)
        lines.append(Localization.string("export.section.reframes", fallback: "== Reframes ==", language: language))
        for r in thoughts {
            let dateLine = String(format: Localization.string("export.reframe.date", fallback: "• %@", language: language), r.date.formatted(date: .complete, time: .shortened))
            lines.append(dateLine)
            if !r.automaticThought.isEmpty {
                let text = String(format: Localization.string("export.reframe.original", fallback: "  Original: %@", language: language), r.automaticThought)
                lines.append(text)
            }
            if !r.reframe.isEmpty {
                let text = String(format: Localization.string("export.reframe.kinder", fallback: "  Kinder perspective: %@", language: language), r.reframe)
                lines.append(text)
            }
            lines.append("")
        }

        // Pressures
        lines.append(Localization.string("export.section.pressures", fallback: "== Everyday Pressures ==", language: language))
        for p in pressures {
            lines.append(String(format: Localization.string("export.pressure.trigger", fallback: "• %@", language: language), p.trigger))
            lines.append(String(format: Localization.string("export.pressure.reframe", fallback: "  Softer take: %@", language: language), p.slip))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func deleteAllData() {
        entries.forEach { e in
            // also delete local image files
            e.photos.forEach { AttachmentStore.delete(filename: $0.filename) }
            context.delete(e)
        }
        thoughts.forEach(context.delete)
        pressures.forEach(context.delete)
        try? context.save()
    }
}

// MARK: – Language model
