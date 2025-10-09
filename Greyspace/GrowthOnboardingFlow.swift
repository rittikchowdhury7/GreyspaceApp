import SwiftUI

struct GrowthOnboardingFlow: View {
    enum Step: Hashable {
        case welcome
        case concept
        case choosePlant
        case confirm(PlantChoice)
    }

    @ObservedObject var store: GardenStore
    let startFirstCheckIn: () -> Void

    @State private var path: [Step] = []
    @State private var selectedRegion: PlantRegion = .homeCountry
    @State private var selectedPlant: PlantChoice?

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(onContinue: { path.append(.concept) })
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .welcome:
                        WelcomeView(onContinue: { path.append(.concept) })
                    case .concept:
                        ConceptView(onContinue: { path.append(.choosePlant) })
                    case .choosePlant:
                        ChoosePlantView(
                            selectedRegion: $selectedRegion,
                            selectedPlant: $selectedPlant,
                            onContinue: {
                                if let plant = selectedPlant {
                                    path.append(.confirm(plant))
                                }
                            }
                        )
                    case .confirm(let plant):
                        ConfirmPlantView(
                            plant: plant,
                            onStart: {
                                store.startRun(with: plant)
                                store.markOnboardingCompleted()
                                startFirstCheckIn() // TODO: Hook into existing Start First Check-In flow.
                            }
                        )
                    }
                }
        }
        .onAppear {
            if path.isEmpty {
                path = [.welcome]
            }
        }
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(String(localized: "Grow With Me"))
                .font(.largeTitle)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text(String(localized: "A gentle space to watch your reflections bloom."))
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: onContinue) {
                Text(String(localized: "Continue"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .accessibilityHint(String(localized: "Move to the next page"))
            Spacer(minLength: 32)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Concept

struct ConceptView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 32)
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(height: 220)
                    VStack(spacing: 16) {
                        // TODO: Replace with seed-to-sprout animation when assets are ready.
                        Image(systemName: "leaf.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundStyle(.green)
                        Text(String(localized: "Every reflection helps your plant grow."))
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                }
                Text(String(localized: "Each day you check in or use Thought Helper, your plant takes another step from seed to bloom. Missed days simply become rest days."))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button(action: onContinue) {
                    Text(String(localized: "Choose a plant"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .accessibilityLabel(String(localized: "Choose a plant to grow"))
                Spacer(minLength: 32)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Choose Plant

struct ChoosePlantView: View {
    @Binding var selectedRegion: PlantRegion
    @Binding var selectedPlant: PlantChoice?
    let onContinue: () -> Void

    private var plants: [PlantChoice] {
        if selectedRegion == .surprise {
            return PlantChoice.samplePlants
        }
        return PlantChoice.samplePlants.filter { $0.region == selectedRegion }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Plant source"), selection: $selectedRegion) {
                ForEach(PlantRegion.allCases) { region in
                    Text(region.displayName).tag(region)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                    ForEach(plants) { plant in
                        PlantChoiceCard(plant: plant, isSelected: plant == selectedPlant)
                            .onTapGesture {
                                if selectedRegion == .surprise {
                                    selectedPlant = PlantChoice.samplePlants.randomElement()
                                } else {
                                    selectedPlant = plant
                                }
                            }
                    }
                }
                .padding()
            }

            Button(action: {
                if selectedPlant == nil, selectedRegion == .surprise {
                    selectedPlant = PlantChoice.samplePlants.randomElement()
                }
                if selectedPlant != nil {
                    onContinue()
                }
            }) {
                Text(String(localized: "Continue"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(selectedPlant == nil && selectedRegion != .surprise)
            .accessibilityLabel(String(localized: "Continue to confirm plant"))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Choose Your Plant"))
    }
}

// MARK: - PlantChoiceCard

struct PlantChoiceCard: View {
    let plant: PlantChoice
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                // TODO: Replace placeholder with illustration asset referenced by plant.assetName.
                Image(systemName: "leaf")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .foregroundColor(.accentColor)
            }
            Text(plant.displayName)
                .font(.headline)
            Text(plant.symbolism)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Confirm

struct ConfirmPlantView: View {
    let plant: PlantChoice
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            PlantChoiceCard(plant: plant, isSelected: true)
            Text(String(localized: "Symbolism"))
                .font(.title3)
                .fontWeight(.semibold)
            Text(plant.symbolism)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button(action: onStart) {
                Text(String(localized: "Start my first check-in"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .accessibilityLabel(String(localized: "Start first check-in"))
            Spacer(minLength: 24)
        }
        .navigationTitle(String(localized: "You chose \(plant.displayName)"))
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Previews

struct GrowthOnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        GrowthOnboardingFlow(store: GardenStore.makeDefault(), startFirstCheckIn: {})
    }
}
