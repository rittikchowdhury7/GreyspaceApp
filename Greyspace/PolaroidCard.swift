//
//  PolaroidCard.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-17.
//


import SwiftUI

struct PolaroidMomentView: View {
    let originalThought: String
    let reframe: String
    var onDone: () -> Void
    var startFlipped: Bool = false
    var showTapHint: Bool = true

    @State private var hasFlippedOnce = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Greyspace Moment")
                    .font(.headline)

                PolaroidCard(
                    original: originalThought,
                    reframe: reframe,
                    onFirstFlip: {
                        hasFlippedOnce = true
                    }
                )
                .frame(height: 320)

                HStack(spacing: 8) {
                    if !hasFlippedOnce {
                        Image(systemName: "hand.point.up.left.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.secondary)
                        Text("Tap the card to reveal your softer thought")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Saved to your Reframe Library")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)

                Button("Done") { onDone() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .padding(16)
        }
    }
}

struct PolaroidCard: View {
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
        .contentShape(RoundedRectangle(cornerRadius: 16))
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
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
                .transition(.opacity)
            }
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (0,1,0))
    }

    // MARK: Faces

    private var faceFront: some View {
        PolaroidFace {
            Text("Original thought")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("“\(original)”")
                .font(.title3)
                .foregroundStyle(.primary)
            Text("Let’s soften it…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var faceBack: some View {
        PolaroidFace {
            Text("Softer thought")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("“\(reframe)”")
                .font(.title3.weight(.semibold))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(glow ? 0.45 : 0.2), lineWidth: glow ? 2 : 1)
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
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
                .padding(16)
            )
    }
}
