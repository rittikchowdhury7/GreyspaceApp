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
            
            VStack(spacing: 16) {
                Text("Thought Helper")
                    .font(.largeTitle).bold()

                Text("This space is for sticky, unhelpful thoughts; The kind of thoughts that loop or weigh on you. "
                     + "We’ll gently walk you through a few steps to look at the thought in a new way. "
                     + "It’s not about fixing or erasing, just softening how it feels.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: onStart) {
                Text("Let’s Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
            }
        }
    }
}
