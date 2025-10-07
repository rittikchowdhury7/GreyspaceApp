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

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            VStack(spacing: 12) {
                Text(title).font(.largeTitle).bold().multilineTextAlignment(.center)
                Text(blurb)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if !points.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points, id: \.self) { p in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "dot.circle.fill").imageScale(.small)
                                .foregroundStyle(.secondary)
                            Text(p)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Toggle("Don’t show again", isOn: $dontShowAgain)
                .font(.callout)
                .padding(.horizontal, 24)

            Button(action: onStart) {
                Text(startLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
            }
            .accessibilityIdentifier("intro.start")
        }
    }
}