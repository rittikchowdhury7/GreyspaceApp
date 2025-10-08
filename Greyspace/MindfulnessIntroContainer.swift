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
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        let language = AppLanguage.resolved(for: appLanguageCode)
        let title = Localization.string("intro.mindfulness.title", fallback: "One-Breath Reset", language: language)
        let blurb = Localization.string("intro.mindfulness.blurb", fallback: "A 10-second reset. Inhale as the circle expands, exhale as it softens. Do 1–3 cycles.", language: language)
        let points = [
            Localization.string("intro.mindfulness.point1", fallback: "No timer pressure — follow the animation.", language: language),
            Localization.string("intro.mindfulness.point2", fallback: "If your mind wanders, that’s okay. Gently return.", language: language),
            Localization.string("intro.mindfulness.point3", fallback: "A tiny pause counts.", language: language)
        ]
        let startLabel = Localization.string("intro.mindfulness.start", fallback: "Begin", language: language)

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
                MindfulnessView()   // your existing breathing circle
            }
        }
    }
}