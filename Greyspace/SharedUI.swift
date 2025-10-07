//
//  SharedUI.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import SwiftUI

// MARK: - Step header with progress
struct StepHeader: View {
    let title: String
    let step: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            ProgressView(value: Double(step), total: Double(total))
                .tint(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Wizard controls (Back / Skip / Next)
struct WizardControls: View {
    var canGoBack: Bool
    var onBack: () -> Void
    var nextTitle: String
    var showSkip: Bool
    var onSkip: () -> Void
    var onNext: () -> Void

    var body: some View {
        HStack {
            if canGoBack {
                Button("Back", action: onBack)
            }
            Spacer()
            if showSkip {
                Button("Skip", action: onSkip).foregroundStyle(.secondary)
            }
            Button(nextTitle, action: onNext)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Key/value line used on review steps
struct SummaryRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline)
        }
    }
}

// MARK: - Breathing circle animation toggle
struct BreathingCircle: View {
    @Binding var active: Bool
    @State private var scale: CGFloat = 0.6

    var body: some View {
        Circle()
            .scaleEffect(scale)
            .animation(active ? .easeInOut(duration: 4).repeatForever(autoreverses: true) : .default,
                       value: scale)
            .onAppear { scale = 1.0 }
            .onChange(of: active) { _, newVal in
                scale = newVal ? 1.0 : 0.9
            }
    }
}

// MARK: - Lightweight wrap flow (chips)
struct FlowLayout<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    var items: Data
    var id: KeyPath<Data.Element, ID>
    var content: (Data.Element) -> Content

    init(items: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.id = id
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(minHeight: 44)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: id) { item in
                content(item)
                    .padding(4)
                    .alignmentGuide(.leading) { d in
                        if (width + d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        width += d.width
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
    }
}
