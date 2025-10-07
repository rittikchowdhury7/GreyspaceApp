//
//  Models.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var mood: Int            // 1–5
    var anxiety: Int         // 0–10
    var gratitude: [String]
    var photos: [ImageAttachment]
    var notes: String
    var tags: [String]
    var didMindfulness: Bool

    init(id: UUID = UUID(),
         date: Date = .now,
         mood: Int = 3,
         anxiety: Int = 0,
         gratitude: [String] = [],
         photos: [ImageAttachment] = [],
         notes: String = "",
         tags: [String] = [],
         didMindfulness: Bool = false) {
        self.id = id
        self.date = date
        self.mood = mood
        self.anxiety = anxiety
        self.gratitude = gratitude
        self.photos = photos
        self.notes = notes
        self.tags = tags
        self.didMindfulness = didMindfulness
    }
}

enum CognitiveDistortion: String, Codable, CaseIterable, Identifiable {
    case allOrNothing = "All-or-Nothing"
    case catastrophizing = "Catastrophizing"
    case mindReading = "Mind Reading"
    case overgeneralization = "Overgeneralization"
    case shouldStatements = "“Should” Statements"
    case discountingPositive = "Discounting the Positive"
    case emotionalReasoning = "Emotional Reasoning"
    case fortuneTelling = "Fortune Telling"

    var id: String { rawValue }
}

@Model
final class ThoughtRecord {
    var id: UUID
    var date: Date
    var situation: String
    var automaticThought: String
    var emotionLabel: String     // e.g., “Anxiety”
    var intensity: Int           // 0–100
    var distortions: [CognitiveDistortion]
    var evidenceFor: String
    var evidenceAgainst: String
    var reframe: String

    init(id: UUID = UUID(),
         date: Date = .now,
         situation: String = "",
         automaticThought: String = "",
         emotionLabel: String = "Anxiety",
         intensity: Int = 40,
         distortions: [CognitiveDistortion] = [],
         evidenceFor: String = "",
         evidenceAgainst: String = "",
         reframe: String = "") {
        self.id = id
        self.date = date
        self.situation = situation
        self.automaticThought = automaticThought
        self.emotionLabel = emotionLabel
        self.intensity = intensity
        self.distortions = distortions
        self.evidenceFor = evidenceFor
        self.evidenceAgainst = evidenceAgainst
        self.reframe = reframe
    }
}
