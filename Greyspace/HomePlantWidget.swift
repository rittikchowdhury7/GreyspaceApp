import SwiftUI

struct HomePlantWidget: View {
    @ObservedObject var store: GardenStore

    private var run: PlantRun? { store.state.activeRun }

    var body: some View {
        Group {
            if let run, !store.state.profile.hidePlantOnHome {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "leaf.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(16)
                                    .foregroundStyle(Color.accentColor)
                            )
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(run.plant.displayName)
                                .font(.headline)
                            Text(run.stage.title)
                                .font(.title3)
                                .bold()
                            Text(String(localized: "Day \(run.dayCount) of 7"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    Text(copy(for: run))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    Text(String(localized: "Your \(run.plant.displayName) is at \(run.stage.title) stage. Day \(run.dayCount) of seven."))
                )
            } else {
                EmptyView()
            }
        }
        .onAppear {
            store.resetRainDayIfNeeded()
        }
    }

    private func copy(for run: PlantRun) -> String {
        if run.isComplete {
            return String(localized: "Seven days of care. Your \(run.plant.displayName) matured.")
        }
        if run.dayCount == 0 {
            return String(localized: "Welcome to your new plant. Each reflection will help it grow.")
        }
        return String(localized: "You watered your \(run.plant.displayName) today. Little steps, real growth.")
    }
}

struct HomePlantWidget_Previews: PreviewProvider {
    static var previews: some View {
        let store = GardenStore.makeDefault()
        store.startRun(with: PlantChoice.samplePlants[0])
        return HomePlantWidget(store: store)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
