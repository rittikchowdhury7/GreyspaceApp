//
//  PressureFlashView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-21.
//


import SwiftUI

struct PressureFlashView: View {
    let items: [PressureSlip]
    let startIndex: Int

    // 👇 make index stateful AND initialize it from startIndex
    @State private var index: Int
    @State private var showPolaroid: Bool = false

    init(items: [PressureSlip], startIndex: Int) {
        self.items = items
        let clamped = max(0, min(startIndex, max(0, items.count - 1)))
        self.startIndex = clamped
        _index = State(initialValue: clamped)   // ← key line
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(items.indices, id: \.self) { i in
                    PolaroidPressureView(
                        originalThought: items[i].trigger,
                        reframe: items[i].slip,
                        onDone: { dismiss() },
                        startFlipped: true,
                        showTapHint: false
                    )
                    .tag(i)
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.md)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .navigationTitle("Everyday Pressures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

struct PolaroidPressureView: View {
    let originalThought: String
    let reframe: String
    var onDone: () -> Void
    var startFlipped: Bool = false
    var showTapHint: Bool = true

    @State private var hasFlippedOnce = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                Text("Everyday Pressure")
                    .font(DS.Typography.heading())

                PolaroidPressure(
                    original: originalThought,
                    reframe: reframe,
                    onFirstFlip: {
                        hasFlippedOnce = true
                    }
                )
                .frame(height: 320)

                HStack(spacing: DS.Spacing.sm) {
                    if !hasFlippedOnce {
                        Image(systemName: "hand.point.up.left.fill")
                            .imageScale(.medium)
                            .foregroundStyle(DS.Color.muted)
                        Text("Tap the card to reveal a kinder perspective")
                            .font(DS.Typography.caption())
                            .foregroundStyle(DS.Color.muted)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(DS.Color.accent)
                        Text("Saved to your Everyday Pressure library")
                            .font(DS.Typography.caption())
                            .foregroundStyle(DS.Color.muted)
                    }
                }
                .padding(.top, DS.Spacing.xs)

                Button("Done") { onDone() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, DS.Spacing.xs)
            }
            .padding(DS.Spacing.lg)
        }
    }
}

struct PolaroidPressure: View {
    let original: String
    let reframe: String
    var startFlipped: Bool = false
    var showTapHint: Bool = true
    var onFirstFlip: (() -> Void)? = nil

    @State private var flipped = false
    @State private var glow = false
    @State private var showedHint = false

    var body: some View {
        ZStack {
            // FRONT
            if !flipped {
                faceFront
                    .rotation3DEffect(.degrees(0), axis: (0,1,0))
            }

            // BACK
            if flipped {
                faceBack
                    .rotation3DEffect(.degrees(180), axis: (0,1,0))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: flipped)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        .onTapGesture {
            let first = !flipped
            withAnimation {
                flipped.toggle()
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if first { // first time we flip to the back
                onFirstFlip?()
                // gentle glow on the reframe text
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
                showedHint = true
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !showedHint && !flipped {
                // subtle hint chip
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                    Text("Tap to flip")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DS.Color.muted)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(DS.Spacing.md)
                .transition(.opacity)
            }
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (0,1,0))
    }

    // MARK: Faces

    private var faceFront: some View {
        PolaroidFace {
            Text("This pressure I carry...")
                .font(DS.Typography.caption()).fontWeight(.semibold)
                .foregroundStyle(DS.Color.muted)
            Text("“\(original)”")
                .font(DS.Typography.heading())
                .foregroundStyle(DS.Color.onSurface)
            Text("Let's find a gentler way to see it...")
                .font(DS.Typography.caption())
                .foregroundStyle(DS.Color.muted)
        }
    }

    private var faceBack: some View {
        PolaroidFace {
            Text("Gentle view")
                .font(DS.Typography.caption()).fontWeight(.semibold)
                .foregroundStyle(DS.Color.muted)
            Text("“\(reframe)”")
                .font(.title3.weight(.semibold))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(DS.Color.accent.opacity(glow ? 0.45 : 0.2), lineWidth: glow ? 2 : 1)
                        .blur(radius: glow ? 1.5 : 0)
                )
                .accessibilityLabel("Reframed thought: \(reframe)")
        }
    }
}

// shared look
private struct PolaroidFace<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        RoundedRectangle(cornerRadius: DS.Radius.lg)
            .fill(DS.Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(DS.Color.muted.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
            .overlay(
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    content
                }
                .padding(DS.Spacing.lg)
            )
    }
}
