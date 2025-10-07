//
//  MindfulnessIntroContainer.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


// MindfulnessIntroContainer.swift
import SwiftUI

struct MindfulnessIntroContainer: View {
    @AppStorage("intro.skip.mindfulness") private var skipIntro = false
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        Group {
            if showIntro && !skipIntro {
                FeatureIntroView(
                    title: "One-Breath Reset",
                    blurb: "A 10-second reset. Inhale as the circle expands, exhale as it softens. Do 1–3 cycles.",
                    points: [
                        "No timer pressure — follow the animation.",
                        "If your mind wanders, that’s okay. Gently return.",
                        "A tiny pause counts."
                    ],
                    dontShowAgain: $localSkip,
                    startLabel: "Begin"
                ) {
                    if localSkip { skipIntro = true }
                    withAnimation { showIntro = false }
                }
            } else {
                MindfulnessView()   // your existing breathing circle
            }
        }
    }
}