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
    @AppStorage("AppLanguage") private var appLanguage: String = "system" // "system","en","hi","fil","zh-Hans"

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
                        ForEach(AppLanguage.all, id: \.code) { lang in
                            Text(lang.display).tag(lang.code)
                        }
                    }
                    .onChange(of: appLanguage) { _ in
                        // If you support live switching, you can refresh views here.
                        // Otherwise iOS will use per-app language in Settings.
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
        lines.append("— Greyspace Export —\n")

        // Journal entries
        lines.append("== Check-Ins ==")
        for e in entries {
            lines.append("• \(e.date.formatted(date: .complete, time: .shortened))")
            lines.append("  Mood \(e.mood)/5 | Anxiety \(e.anxiety)/10")
            if !e.gratitude.isEmpty { lines.append("  Gratitude: " + e.gratitude.joined(separator: ", ")) }
            if !e.notes.isEmpty { lines.append("  Notes: \(e.notes)") }
            if e.didMindfulness { lines.append("  Mindfulness: ✓") }
            if !e.photos.isEmpty { lines.append("  Photos: \(e.photos.count) (stored locally)") }
            lines.append("")
        }

        // Thought records (reframes)
        lines.append("== Reframes ==")
        for r in thoughts {
            lines.append("• \(r.date.formatted(date: .complete, time: .shortened))")
            if !r.automaticThought.isEmpty { lines.append("  Original: \(r.automaticThought)") }
            if !r.reframe.isEmpty { lines.append("  Kinder perspective: \(r.reframe)") }
            lines.append("")
        }

        // Pressures
        lines.append("== Everyday Pressures ==")
        for p in pressures {
            lines.append("• \(p.trigger)")
            lines.append("  Softer take: \(p.slip)")
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

struct AppLanguage: Identifiable, Hashable {
    let id = UUID()
    let code: String   // "system","en","hi","fil","zh-Hans"
    let display: String

    static let all: [AppLanguage] = [
        AppLanguage(code: "system", display: "System"),
        AppLanguage(code: "en",     display: "English"),
        AppLanguage(code: "hi",     display: "Hindi"),
        AppLanguage(code: "fil",    display: "Tagalog"),
        AppLanguage(code: "zh-Hans",display: "Chinese (Simplified)")
    ]
}
