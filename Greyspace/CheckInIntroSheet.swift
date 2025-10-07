//
//  CheckInIntroSheet.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


import SwiftUI

struct CheckInIntroSheet: View {
    @AppStorage("intro.skip.checkin") private var skipIntro = false
    @State private var localSkip = false
    let onStart: () -> Void

    var body: some View {
        FeatureIntroView(
            title: "Daily Check-In",
            blurb: "Take a 60-second snapshot of your mood, stress, gratitude, and notes. Add photos if you like. It’s private, stored only on your device.",
            points: [
                "Rate mood & anxiety quickly",
                "Optional gratitude and notes",
                "Capture your day with photos"
            ],
            dontShowAgain: $localSkip,
            startLabel: "Start Check-In"
        ) {
            if localSkip { skipIntro = true }
            onStart()
        }
    }
}