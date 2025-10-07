//
//  ThoughtHelperContainer.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//

import SwiftUI

struct ThoughtHelperContainer: View {
    @AppStorage("intro.skip.thoughtHelper") private var skipIntro = false
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        Group {
            if showIntro && !skipIntro {
                FeatureIntroView(
                    title: "Thought Helper",
                    blurb: "This space is for sticky, unhelpful thoughts; The kind that loop or weigh on you. We’ll gently walk through a few steps to find a kinder perspective. Not fixing, just softening.",
                    points: [
                        "Start with one real thought (not a question).",
                        "Name the feeling it brings up.",
                        "Pick a gentler way to see it or write your own (AI can help!)."
                    ],
                    dontShowAgain: $localSkip,
                    startLabel: "Let’s Start"
                ) {
                    if localSkip { skipIntro = true }
                    withAnimation { showIntro = false }
                }
            } else {
                ThoughtBuilderWizard()
            }
        }
    }
}
