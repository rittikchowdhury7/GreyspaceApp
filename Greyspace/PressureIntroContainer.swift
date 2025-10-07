//
//  PressureIntroContainer.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


// PressureIntroContainer.swift
import SwiftUI

struct PressureIntroContainer: View {
    @AppStorage("intro.skip.pressures") private var skipIntro = false
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        Group {
            if showIntro && !skipIntro {
                FeatureIntroView(
                    title: "Everyday Pressures",
                    blurb: "Quick cards for common cultural and family pressures. Flip for a kinder perspective, or add your own with optional AI help.",
                    points: [
                        "Tap a card to flip for a lighter take.",
                        "Swipe through the deck for ideas.",
                        "Add your own pressure and save reframes."
                    ],
                    dontShowAgain: $localSkip,
                    startLabel: "Browse Cards"
                ) {
                    if localSkip { skipIntro = true }
                    withAnimation { showIntro = false }
                }
            } else {
                PressureListView()   // your existing list/grid
            }
        }
    }
}