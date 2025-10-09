import Foundation

// MARK: - GardenStorage Protocol

protocol GardenStorage {
    func loadState() -> GardenState
    func save(state: GardenState)
}

// MARK: - SwiftData Storage

#if canImport(SwiftData)
import SwiftData

@available(iOS 17, *)
final class GardenStoreSwiftData: GardenStorage {
    private let container: ModelContainer

    @Model
    final class GardenStateModel {
        @Attribute(.unique) var key: String
        var data: Data

        init(key: String, data: Data) {
            self.key = key
            self.data = data
        }
    }

    init(container: ModelContainer = {
        let schema = Schema([GardenStateModel.self])
        return try! ModelContainer(for: schema)
    }()) {
        self.container = container
    }

    func loadState() -> GardenState {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<GardenStateModel>(predicate: #Predicate { $0.key == "state" })
        if let model = try? context.fetch(descriptor).first,
           let state = try? JSONDecoder().decode(GardenState.self, from: model.data) {
            return state
        }
        return GardenState()
    }

    func save(state: GardenState) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<GardenStateModel>(predicate: #Predicate { $0.key == "state" })
        let data = (try? JSONEncoder().encode(state)) ?? Data()
        if let model = try? context.fetch(descriptor).first {
            model.data = data
            try? context.save()
        } else {
            let model = GardenStateModel(key: "state", data: data)
            context.insert(model)
            try? context.save()
        }
    }
}
#endif

// MARK: - UserDefaults Storage

final class GardenStoreUserDefaults: GardenStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadState() -> GardenState {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Keys.state),
           let state = try? decoder.decode(GardenState.self, from: data) {
            return state
        }

        var state = GardenState()
        var didLoadLegacy = false

        if defaults.object(forKey: LegacyKeys.hasCompletedOnboarding) != nil {
            state.hasCompletedOnboarding = defaults.bool(forKey: LegacyKeys.hasCompletedOnboarding)
            didLoadLegacy = true
        }

        if let data = defaults.data(forKey: LegacyKeys.activeRun),
           let run = try? decoder.decode(PlantRun.self, from: data) {
            state.activeRun = run
            didLoadLegacy = true
        }

        if let data = defaults.data(forKey: LegacyKeys.completedRuns),
           let runs = try? decoder.decode([PlantRun].self, from: data) {
            state.completedRuns = runs
            didLoadLegacy = true
        }

        if let data = defaults.data(forKey: LegacyKeys.profile),
           let profile = try? decoder.decode(GardenProfile.self, from: data) {
            state.profile = profile
            didLoadLegacy = true
        }

        if let data = defaults.data(forKey: LegacyKeys.flags),
           let flags = try? decoder.decode(GardenFlags.self, from: data) {
            state.flags = flags
            didLoadLegacy = true
        }

        if didLoadLegacy {
            save(state: state)
            return state
        }

        return GardenState()
    }

    func save(state: GardenState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Keys.state)
    }

    private enum Keys {
        static let state = "garden.state"
    }

    private enum LegacyKeys {
        static let hasCompletedOnboarding = "garden.hasCompletedOnboarding"
        static let activeRun = "garden.activeRun"
        static let completedRuns = "garden.completedRuns"
        static let profile = "garden.profile"
        static let flags = "garden.flags"
    }
}

// MARK: - GardenStore

@MainActor
final class GardenStore: ObservableObject {
    @Published private(set) var state: GardenState

    private let storage: GardenStorage
    private let calendar: Calendar

    init(
        storage: GardenStorage,
        initialState: GardenState? = nil,
        calendar: Calendar = .current
    ) {
        self.storage = storage
        self.calendar = calendar
        self.state = initialState ?? storage.loadState()
    }

    static func makeDefault() -> GardenStore {
        #if canImport(SwiftData)
        if #available(iOS 17, *) {
            return GardenStore(storage: GardenStoreSwiftData())
        }
        #endif
        return GardenStore(storage: GardenStoreUserDefaults())
    }

    // MARK: - Onboarding

    func markOnboardingCompleted() {
        state.hasCompletedOnboarding = true
        persist()
    }

    func resetOnboarding() {
        state.hasCompletedOnboarding = false
        persist()
    }

    // MARK: - Plant Lifecycle

    func startRun(with plant: PlantChoice) {
        state.activeRun = PlantRun(plant: plant, startDate: Date())
        persist()
    }

    func abandonRun() {
        state.activeRun = nil
        persist()
    }

    @discardableResult
    func recordDailyProgress(
        action: GrowthActionType,
        on date: Date = Date()
    ) -> PlantRun? {
        guard var run = state.activeRun else {
            return nil
        }
        if run.isComplete {
            if run.nurtureModeEnabled {
                let entry = PlantRun.DailyEntry(dayIndex: PlantStage.mature.rawValue, date: date)
                run.completedEntries.append(entry)
                run = refreshWeeklyBlossomIfNeeded(for: run, on: date)
                state.activeRun = run
                if let index = state.completedRuns.firstIndex(where: { $0.id == run.id }) {
                    state.completedRuns[index] = run
                }
                persist()
            }
            return run
        }
        guard !run.hasCompletedEntry(on: date, calendar: calendar) else {
            return run
        }

        let nextIndex = run.nextDayIndex()
        run.completedEntries.append(.init(dayIndex: nextIndex, date: date))
        state.activeRun = run
        persist()

        if run.isComplete {
            completeActiveRun()
        }

        return state.activeRun
    }

    private func completeActiveRun() {
        guard var run = state.activeRun else { return }
        run = refreshWeeklyBlossomIfNeeded(for: run)
        state.completedRuns.append(run)
        state.activeRun = run
        persist()
    }

    func enableNurtureModeForActiveRun() {
        guard var run = state.activeRun else { return }
        run.nurtureModeEnabled = true
        state.activeRun = run
        if let index = state.completedRuns.firstIndex(where: { $0.id == run.id }) {
            state.completedRuns[index] = run
        }
        persist()
    }

    func updateProfile(_ update: (inout GardenProfile) -> Void) {
        update(&state.profile)
        persist()
    }

    func resetRainDayIfNeeded(on date: Date = Date()) {
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        if state.flags.lastRainWeekOfYear != weekOfYear {
            state.flags.rainDaysRemainingThisWeek = 1
            state.flags.lastRainWeekOfYear = weekOfYear
            persist()
        }
    }

    func useRainDayIfAvailable(on date: Date = Date()) -> Bool {
        resetRainDayIfNeeded(on: date)
        guard state.flags.rainDaysRemainingThisWeek > 0 else { return false }
        state.flags.rainDaysRemainingThisWeek -= 1
        persist()
        return true
    }

    func refreshWeeklyBlossomIfNeeded(for run: PlantRun, on date: Date = Date()) -> PlantRun {
        var mutableRun = run
        let entriesThisWeek = run.completedEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: date, toGranularity: .weekOfYear)
        }
        mutableRun.weeklyBlossomEarned = entriesThisWeek.count >= 4
        return mutableRun
    }

    func startNewSeed(with plant: PlantChoice) {
        startRun(with: plant)
    }

    // MARK: - Persistence

    private func persist() {
        storage.save(state: state)
    }
}

// MARK: - Plant Library

protocol GrowWithMeProgressHandling {
    func growWithMeDidComplete(action: GrowthActionType, at date: Date)
}

extension GardenStore: GrowWithMeProgressHandling {
    func growWithMeDidComplete(action: GrowthActionType, at date: Date) {
        _ = recordDailyProgress(action: action, on: date)
    }
}

