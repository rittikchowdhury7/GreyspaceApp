import SwiftUI

struct GardenView: View {
    @ObservedObject var store: GardenStore
    @State private var selection: Tab = .inProgress
    @State private var showCompletionCard: Bool = false

    enum Tab: String, CaseIterable, Identifiable {
        case inProgress
        case myGarden
        case discover

        var id: String { rawValue }

        var title: String {
            switch self {
            case .inProgress:
                return String(localized: "In Progress")
            case .myGarden:
                return String(localized: "My Garden")
            case .discover:
                return String(localized: "Discover")
            }
        }
    }

    private var activeRun: PlantRun? { store.state.activeRun }

    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            tabContent
        }
        .sheet(isPresented: $showCompletionCard) {
            CompletionCard(store: store, isPresented: $showCompletionCard)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: store.state.completedRuns) { _ in
            if let last = store.state.completedRuns.last, calendar.isDateInToday(last.completedEntries.last?.date ?? Date()) {
                showCompletionCard = true
            }
        }
        .onAppear {
            store.resetRainDayIfNeeded()
            if activeRun?.isComplete == true {
                showCompletionCard = true
            }
        }
        .navigationTitle(String(localized: "Garden"))
    }

    private var tabContent: some View {
        Group {
            switch selection {
            case .inProgress:
                InProgressView(store: store)
            case .myGarden:
                CompletedGardenView(completedRuns: store.state.completedRuns)
            case .discover:
                DiscoverView()
            }
        }
    }

    private var calendar: Calendar { .current }
}

// MARK: - In Progress

private struct InProgressView: View {
    @ObservedObject var store: GardenStore

    private var activeRun: PlantRun? { store.state.activeRun }

    var body: some View {
        VStack(spacing: 24) {
            if let run = activeRun {
                ProgressRing(run: run)
                Button(action: {
                    // TODO: Link to the existing check-in or Thought Helper action.
                }) {
                    Text(String(localized: "Continue today's care"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                Text(String(localized: "Your plant is resting when you are. Check in when you're ready."))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text(String(localized: "No active plants. Plant a new seed to begin."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        }
    }
}

private struct ProgressRing: View {
    let run: PlantRun

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 1)
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .trim(from: 0, to: CGFloat(run.dayCount) / 7.0)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: run.dayCount)

            VStack(spacing: 8) {
                Text(run.stage.title)
                    .font(.title3)
                    .bold()
                Text(String(localized: "Day \(run.dayCount) of 7"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "\(run.stage.title). Day \(run.dayCount) of seven."))
        }
        .frame(width: 200, height: 200)
        .padding()
    }
}

// MARK: - Completed Garden

private struct CompletedGardenView: View {
    let completedRuns: [PlantRun]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(completedRuns) { run in
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "leaf")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(32)
                                    .foregroundColor(.accentColor)
                            )
                        Text(run.plant.displayName)
                            .font(.headline)
                        if let date = run.completedEntries.last?.date {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(run.plant.symbolism)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    )
                    .accessibilityElement(children: .combine)
                }
            }
            .padding()
        }
    }
}

// MARK: - Discover

private struct DiscoverView: View {
    let lockedPlants: [PlantChoice] = PlantChoice.samplePlants

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(lockedPlants) { plant in
                    HStack(alignment: .center, spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plant.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(plant.symbolism)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(localized: "Complete mindful care to unlock."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGroupedBackground))
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Completion Card

private struct CompletionCard: View {
    @ObservedObject var store: GardenStore
    @Binding var isPresented: Bool

    @State private var confettiOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.accentColor.opacity(0.1))
                .frame(height: 180)
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                            .opacity(confettiOpacity)
                            .animation(.easeInOut(duration: 1.0), value: confettiOpacity)
                        Text(String(localized: "Seven days of care"))
                            .font(.title2)
                            .bold()
                        if let plant = store.state.completedRuns.last?.plant {
                            Text(String(localized: "Your \(plant.displayName) matured."))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                )
            VStack(spacing: 12) {
                Button {
                    isPresented = false
                    if let plant = store.state.completedRuns.last?.plant {
                        store.startNewSeed(with: plant)
                    }
                } label: {
                    Text(String(localized: "Plant New Seed"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isPresented = false
                    store.enableNurtureModeForActiveRun()
                } label: {
                    Text(String(localized: "Nurture Mode"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiOpacity = 1
            }
        }
    }
}

struct GardenView_Previews: PreviewProvider {
    static var previews: some View {
        GardenView(store: GardenStore.makeDefault())
    }
}
