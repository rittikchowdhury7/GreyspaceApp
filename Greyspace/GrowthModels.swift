import Foundation
import SwiftUI

// MARK: - PlantRegion

public enum PlantRegion: String, CaseIterable, Codable, Identifiable {
    case homeCountry
    case currentRegion
    case surprise

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .homeCountry:
            return String(localized: "Home Country")
        case .currentRegion:
            return String(localized: "Where I Am Now")
        case .surprise:
            return String(localized: "Surprise Me")
        }
    }
}

// MARK: - PlantStage

public enum PlantStage: Int, CaseIterable, Codable, Identifiable {
    case seed = 1
    case sprout
    case leaf
    case bud
    case earlyBloom
    case fullBloom
    case mature

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .seed:
            return String(localized: "Seed")
        case .sprout:
            return String(localized: "Sprout")
        case .leaf:
            return String(localized: "Leaf")
        case .bud:
            return String(localized: "Bud")
        case .earlyBloom:
            return String(localized: "Early Bloom")
        case .fullBloom:
            return String(localized: "Full Bloom")
        case .mature:
            return String(localized: "Mature")
        }
    }

    public var accessibilityDescription: String {
        String(localized: "Stage \(rawValue): \(title)")
    }
}

// MARK: - PlantChoice

public struct PlantChoice: Identifiable, Codable, Equatable {
    public let id: String
    public let displayName: String
    public let symbolism: String
    public let regionTag: String
    public let region: PlantRegion
    let assetNameOverride: String?

    public var assetName: String {
        assetNameOverride ?? "plant_\(id)"
    }

    public init(
        id: String,
        displayName: String,
        regionTag: String,
        symbolism: String,
        assetName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.regionTag = regionTag
        self.symbolism = symbolism
        self.region = PlantChoice.mapRegion(from: regionTag)
        self.assetNameOverride = assetName
    }

    private static func mapRegion(from tag: String) -> PlantRegion {
        switch tag.lowercased() {
        case "homecountry":
            return .homeCountry
        case "currentregion":
            return .currentRegion
        default:
            return .surprise
        }
    }
}

extension PlantChoice {
    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case symbolism
        case regionTag
        case region
        case assetNameOverride
        case assetName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let decodedID = try? container.decode(String.self, forKey: .id) {
            id = decodedID
        } else if let legacyID = try? container.decode(UUID.self, forKey: .id) {
            id = legacyID.uuidString
        } else {
            id = UUID().uuidString
        }

        displayName = (try? container.decode(String.self, forKey: .displayName)) ?? ""
        symbolism = (try? container.decode(String.self, forKey: .symbolism)) ?? ""

        if let decodedTag = try? container.decode(String.self, forKey: .regionTag) {
            regionTag = decodedTag
            region = PlantChoice.mapRegion(from: decodedTag)
        } else if let legacyRegion = try? container.decode(PlantRegion.self, forKey: .region) {
            region = legacyRegion
            switch legacyRegion {
            case .homeCountry:
                regionTag = "HomeCountry"
            case .currentRegion:
                regionTag = "CurrentRegion"
            case .surprise:
                regionTag = "Surprise"
            }
        } else {
            regionTag = "Surprise"
            region = .surprise
        }

        if let override = try? container.decode(String.self, forKey: .assetNameOverride) {
            assetNameOverride = override
        } else if let legacyAssetName = try? container.decode(String.self, forKey: .assetName) {
            assetNameOverride = legacyAssetName
        } else {
            assetNameOverride = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(symbolism, forKey: .symbolism)
        try container.encode(regionTag, forKey: .regionTag)
        try container.encode(region.rawValue, forKey: .region)
        try container.encodeIfPresent(assetNameOverride, forKey: .assetNameOverride)
    }
}

// MARK: - Plant Catalog

public enum PlantCatalog {
    public static let byRegion: [String: [PlantChoice]] = [
        "South Asia": [
            .init(id: "lotus", displayName: "Lotus", regionTag: "HomeCountry", symbolism: "renewal"),
            .init(id: "banyan", displayName: "Banyan", regionTag: "HomeCountry", symbolism: "resilience")
        ],
        "Middle East": [
            .init(id: "jasmine", displayName: "Jasmine", regionTag: "HomeCountry", symbolism: "peace"),
            .init(id: "olive", displayName: "Olive", regionTag: "HomeCountry", symbolism: "endurance")
        ],
        "East Asia": [
            .init(id: "bamboo", displayName: "Bamboo", regionTag: "HomeCountry", symbolism: "balance"),
            .init(id: "plum", displayName: "Plum Blossom", regionTag: "HomeCountry", symbolism: "endurance")
        ],
        "Canada": [
            .init(id: "maple", displayName: "Maple", regionTag: "CurrentRegion", symbolism: "steadfastness"),
            .init(id: "prairie-rose", displayName: "Prairie Rose", regionTag: "CurrentRegion", symbolism: "hope")
        ],
        "Universal": [
            .init(id: "lavender", displayName: "Lavender", regionTag: "Universal", symbolism: "calm"),
            .init(id: "cactus", displayName: "Cactus", regionTag: "Universal", symbolism: "resilience"),
            .init(id: "fern", displayName: "Fern", regionTag: "Universal", symbolism: "renewal"),
            .init(id: "sunflower", displayName: "Sunflower", regionTag: "optimism", symbolism: "optimism")
        ]
    ]

    public static var allPlants: [PlantChoice] {
        byRegion
            .sorted { $0.key < $1.key }
            .flatMap { $0.value }
    }
}

extension PlantChoice {
    public static var samplePlants: [PlantChoice] {
        PlantCatalog.allPlants
    }
}

// MARK: - PlantRun

public struct PlantRun: Identifiable, Codable, Equatable {
    public struct DailyEntry: Codable, Hashable {
        public let dayIndex: Int
        public let date: Date

        public init(dayIndex: Int, date: Date) {
            self.dayIndex = dayIndex
            self.date = date
        }
    }

    public let id: UUID
    public let plant: PlantChoice
    public var startDate: Date
    public var completedEntries: [DailyEntry]
    public var nurtureModeEnabled: Bool
    public var weeklyBlossomEarned: Bool

    public init(
        id: UUID = UUID(),
        plant: PlantChoice,
        startDate: Date = Date(),
        completedEntries: [DailyEntry] = [],
        nurtureModeEnabled: Bool = false,
        weeklyBlossomEarned: Bool = false
    ) {
        self.id = id
        self.plant = plant
        self.startDate = startDate
        self.completedEntries = completedEntries
        self.nurtureModeEnabled = nurtureModeEnabled
        self.weeklyBlossomEarned = weeklyBlossomEarned
    }

    public var dayCount: Int {
        min(completedEntries.count, PlantStage.allCases.count)
    }

    public var stage: PlantStage {
        PlantStage(rawValue: max(1, min(dayCount, PlantStage.allCases.count))) ?? .seed
    }

    public var isComplete: Bool {
        dayCount >= PlantStage.allCases.count
    }

    public func hasCompletedEntry(on date: Date, calendar: Calendar = .current) -> Bool {
        completedEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }

    public func nextDayIndex() -> Int {
        min(completedEntries.count + 1, PlantStage.allCases.count)
    }
}

// MARK: - GardenProfile

public struct GardenProfile: Codable, Equatable {
    public var hidePlantOnHome: Bool
    public var compassionMode: Bool
    public var preferThoughtHelperForGrowth: Bool

    public init(
        hidePlantOnHome: Bool = false,
        compassionMode: Bool = false,
        preferThoughtHelperForGrowth: Bool = false
    ) {
        self.hidePlantOnHome = hidePlantOnHome
        self.compassionMode = compassionMode
        self.preferThoughtHelperForGrowth = preferThoughtHelperForGrowth
    }
}

// MARK: - GardenFlags

public struct GardenFlags: Codable, Equatable {
    public var rainDaysRemainingThisWeek: Int
    public var lastRainWeekOfYear: Int

    public init(rainDaysRemainingThisWeek: Int = 1, lastRainWeekOfYear: Int = -1) {
        self.rainDaysRemainingThisWeek = rainDaysRemainingThisWeek
        self.lastRainWeekOfYear = lastRainWeekOfYear
    }
}

// MARK: - GardenState

public struct GardenState: Codable, Equatable {
    public var hasCompletedOnboarding: Bool
    public var activeRun: PlantRun?
    public var completedRuns: [PlantRun]
    public var profile: GardenProfile
    public var flags: GardenFlags

    public init(
        hasCompletedOnboarding: Bool = false,
        activeRun: PlantRun? = nil,
        completedRuns: [PlantRun] = [],
        profile: GardenProfile = GardenProfile(),
        flags: GardenFlags = GardenFlags()
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.activeRun = activeRun
        self.completedRuns = completedRuns
        self.profile = profile
        self.flags = flags
    }
}

// MARK: - GrowthActionType

public enum GrowthActionType: String, Codable {
    case checkIn
    case thoughtHelper
}
