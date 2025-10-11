import SwiftUI

struct GrowthSettingsSection: View {
    @ObservedObject var store: GardenStore

    var body: some View {
        Section(header: Text(String(localized: "Grow With Me"))) {
            Toggle(isOn: Binding(
                get: { store.state.profile.hidePlantOnHome },
                set: { newValue in
                    store.updateProfile { $0.hidePlantOnHome = newValue }
                }
            )) {
                Text(String(localized: "Hide plant on Home"))
            }

            Toggle(isOn: Binding(
                get: { store.state.profile.compassionMode },
                set: { newValue in
                    store.updateProfile { $0.compassionMode = newValue }
                }
            )) {
                Text(String(localized: "Compassion Mode"))
            }
            .accessibilityHint(String(localized: "Removes visible streak visuals."))
        }
    }
}

struct GrowthSettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            GrowthSettingsSection(store: GardenStore.makeDefault())
        }
    }
}
