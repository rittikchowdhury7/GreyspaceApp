//
//  ThoughtHelperIntroView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-10-01.
//


import SwiftUI

struct ThoughtHelperIntroView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            VStack(spacing: DS.Spacing.lg) {
                Text("Thought Helper")
                    .font(DS.Typography.display()).bold()

                Text("This space is for sticky, unhelpful thoughts; The kind of thoughts that loop or weigh on you. "
                     + "We’ll gently walk you through a few steps to look at the thought in a new way. "
                     + "It’s not about fixing or erasing, just softening how it feels.")
                    .multilineTextAlignment(.center)
                    .font(DS.Typography.body())
                    .foregroundStyle(DS.Color.muted)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer()

            Button(action: onStart) {
                Text("Let’s Start")
                    .font(DS.Typography.heading())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DS.Color.accent, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .foregroundColor(DS.Color.onSurface)
                    .padding(.horizontal, DS.Spacing.xl)
            }
        }
    }
}
