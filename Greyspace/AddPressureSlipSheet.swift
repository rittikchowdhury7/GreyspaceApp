//
//  AddPressureSlipSheet.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-21.
//


import SwiftUI
import SwiftData

struct AddPressureSlipSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var softer: String = ""
    @State private var isLoadingAI = false
    @State private var aiError: String?
    
    // Uses your existing service. If no key, it’ll be nil → AI button disabled.
    private let aiService = AIReframeService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Everyday pressure") {
                    TextField("What’s the pressure?", text: $title, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section("Softer take") {
                    TextEditor(text: $softer)
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.muted.opacity(0.3)))
                    
                    if let aiError {
                        Text(aiError).font(DS.Typography.caption()).foregroundStyle(DS.Color.danger)
                    }
                    
                    HStack {
                        Button {
                            Task { await askAI() }
                        } label: {
                            if isLoadingAI {
                                HStack(spacing: DS.Spacing.sm) { ProgressView(); Text("Asking AI…") }
                            } else {
                                Label("Suggest with AI", systemImage: "sparkles")
                            }
                        }
                        .disabled(title.trimmed.isEmpty || isLoadingAI || aiService == nil)
                        
                        Spacer()
                        
                        if aiService != nil {
                            HStack(spacing: DS.Spacing.xs) {
                                Image(systemName: "sparkles").imageScale(.small)
                                Text("AI").font(DS.Typography.caption()).fontWeight(.semibold)
                            }
                            .padding(.horizontal, DS.Spacing.sm).padding(.vertical, DS.Spacing.xs)
                            .background(DS.Color.accent.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(DS.Color.accent.opacity(0.35), lineWidth: 1))
                            .foregroundStyle(DS.Color.accent)
                        } else {
                            Text("No API key")
                                .font(DS.Typography.caption())
                                .foregroundStyle(DS.Color.muted)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Color.background)
            .navigationTitle("New pressure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmed.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let item = PressureSlip(trigger: title.trimmed, slip: softer.trimmed)
        context.insert(item)
        try? context.save()
        dismiss()
    }
    
    private func askAI() async {
        guard let aiService = try? AIReframeService() else { return }
        let thought = title.trimmed
        guard !thought.isEmpty else { return }
        
        isLoadingAI = true
        aiError = nil
        do {
            // Ask for a few, use the first
            let ideas: [String] = try await aiService.suggestReframes(
                thought: thought,
                feeling: "stress",
                why: "",
                limit: 3
            )
            let best = ideas.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            await MainActor.run {
                withAnimation { softer = best }
            }
        } catch {
            await MainActor.run {
                aiError = error.localizedDescription
            }
        }
        isLoadingAI = false
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
// cooladad
