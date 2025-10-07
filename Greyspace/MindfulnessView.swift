//
//  MindfulnessView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI

struct MindfulnessView: View {
    @State private var scale: CGFloat = 0.6
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 24) {
            Text("One-Breath Reset")
                .font(.title2).bold()
            Text("Inhale as the circle expands. Exhale as it shrinks. Do 3 cycles.")
                .multilineTextAlignment(.center)

            Circle()
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: scale)
                .frame(width: 180, height: 180)
                .onAppear {
                    isRunning = true
                    scale = 1.0
                }
                .onDisappear {
                    isRunning = false
                }
        }
        .padding()
    }
}
