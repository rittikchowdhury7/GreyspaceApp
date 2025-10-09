//
//  FeatureIntroView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


// FeatureIntroView.swift
import SwiftUI

struct FeatureIntroView: View {
    let title: String
    let blurb: String
    let points: [String]    // short bullets (optional)
    @Binding var dontShowAgain: Bool
    let startLabel: String
    let onStart: () -> Void
    let language: AppLanguage

    var body: some View {
        let dontShowLabel = Localization.string("intro.toggle.dontShow", fallback: "Don’t show again", language: language)

        VStack(spacing: DS.Spacing.xl) {
            Spacer(minLength: 12)

            VStack(spacing: DS.Spacing.md) {
                Text(title)
                    .font(DS.Typography.display())
                    .multilineTextAlignment(.center)
                Text(blurb)
                    .font(DS.Typography.body())
                    .foregroundStyle(DS.Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            if !points.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    ForEach(points, id: \.self) { p in
                        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                            Image(systemName: "dot.circle.fill").imageScale(.small)
                                .foregroundStyle(DS.Color.muted)
                            Text(p)
                                .font(DS.Typography.body())
                                .foregroundStyle(DS.Color.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer()

            Toggle(dontShowLabel, isOn: $dontShowAgain)
                .font(DS.Typography.body())
                .padding(.horizontal, DS.Spacing.xl)

            Button(action: onStart) {
                Text(startLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, DS.Spacing.xl)
            .accessibilityIdentifier("intro.start")
        }
    }
}