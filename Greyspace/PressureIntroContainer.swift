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
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode
    @State private var localSkip = false
    @State private var showIntro = true

    var body: some View {
        let language = AppLanguage.resolved(for: appLanguageCode)
        let title = Localization.string("intro.pressure.title", fallback: "Everyday Pressures", language: language)
        let blurb = Localization.string("intro.pressure.blurb", fallback: "Quick cards for common cultural and family pressures. Flip for a kinder perspective, or add your own with optional AI help.", language: language)
        let points = [
            Localization.string("intro.pressure.point1", fallback: "Tap a card to flip for a lighter take.", language: language),
            Localization.string("intro.pressure.point2", fallback: "Swipe through the deck for ideas.", language: language),
            Localization.string("intro.pressure.point3", fallback: "Add your own pressure and save reframes.", language: language)
        ]
        let startLabel = Localization.string("intro.pressure.start", fallback: "Browse Cards", language: language)

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
                PressureListView()   // your existing list/grid
            }
        }
    }
}