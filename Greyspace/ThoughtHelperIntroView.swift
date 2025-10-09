//
//  ThoughtHelperIntroView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


import SwiftUI

struct ThoughtHelperIntroView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode
    var onStart: () -> Void

    var body: some View {
        let language = AppLanguage.resolved(for: appLanguageCode)
        let title = Localization.string("intro.thought.title", fallback: "Thought Helper", language: language)
        let blurb = Localization.string(
            "intro.thought.blurb",
            fallback: "This space is for sticky, unhelpful thoughts; the kind of thoughts that loop or weigh on you. We’ll gently walk you through a few steps to look at the thought in a new way. It’s not about fixing or erasing, just softening how it feels.",
            language: language
        )
        let startLabel = Localization.string("intro.thought.start", fallback: "Let’s Start", language: language)

        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: DS.Spacing.lg) {
                Text(title)
                    .font(DS.Typography.display())

                Text(blurb)
                    .multilineTextAlignment(.center)
                    .font(DS.Typography.body())
                    .foregroundStyle(DS.Color.muted)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer()

            Button(action: onStart) {
                Text(startLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, DS.Spacing.xl)
        }
    }
}
