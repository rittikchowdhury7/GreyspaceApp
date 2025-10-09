//
//  CheckInIntroSheet.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


import SwiftUI

struct CheckInIntroSheet: View {
    @AppStorage("intro.skip.checkin") private var skipIntro = false
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode
    @State private var localSkip = false
    let onStart: () -> Void

    var body: some View {
        let language = AppLanguage.resolved(for: appLanguageCode)
        let title = Localization.string("intro.checkin.title", fallback: "Daily Check-In", language: language)
        let blurb = Localization.string("intro.checkin.blurb", fallback: "Take a 60-second snapshot of your mood, stress, gratitude, and notes. Add photos if you like. It’s private, stored only on your device.", language: language)
        let points = [
            Localization.string("intro.checkin.point1", fallback: "Rate mood & anxiety quickly", language: language),
            Localization.string("intro.checkin.point2", fallback: "Optional gratitude and notes", language: language),
            Localization.string("intro.checkin.point3", fallback: "Capture your day with photos", language: language)
        ]
        let startLabel = Localization.string("intro.checkin.start", fallback: "Start Check-In", language: language)

        return FeatureIntroView(
            title: title,
            blurb: blurb,
            points: points,
            dontShowAgain: $localSkip,
            startLabel: startLabel,
            onStart: {
                if localSkip { skipIntro = true }
                onStart()
            },
            language: language
        )
    }
}