//
//  ThoughtHelperContainer.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//

import SwiftUI

struct ThoughtHelperContainer: View {
    @AppStorage("intro.skip.thoughtHelper") private var skipIntro = false
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        let language = AppLanguage.resolved(for: appLanguageCode)
        let title = Localization.string("intro.thought.title", fallback: "Thought Helper", language: language)
        let blurb = Localization.string(
            "intro.thought.container.blurb",
            fallback: "This space is for sticky, unhelpful thoughts; the kind that loop or weigh on you. We’ll gently walk through a few steps to find a kinder perspective. Not fixing, just softening.",
            language: language
        )
        let points = [
            Localization.string("intro.thought.point1", fallback: "Start with one real thought (not a question).", language: language),
            Localization.string("intro.thought.point2", fallback: "Name the feeling it brings up.", language: language),
            Localization.string("intro.thought.point3", fallback: "Pick a gentler way to see it or write your own (AI can help!).", language: language)
        ]
        let startLabel = Localization.string("intro.thought.start", fallback: "Let’s Start", language: language)

        Group {
            if showIntro && !skipIntro {
                FeatureIntroView(
                    title: title,
                    blurb: blurb,
                    points: points,
                    dontShowAgain: $localSkip,
                    startLabel: startLabel,
                    language: language
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
