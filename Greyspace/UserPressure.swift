//
//  UserPressure.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-21.
//


// UserPressure.swift
import SwiftData
import Foundation

@Model
final class UserPressure {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String            // “the pressure” (card front)
    var softerTake: String       // “softer reframe” (card back)

    init(id: UUID = UUID(), createdAt: Date = .now, title: String, softerTake: String = "") {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.softerTake = softerTake
    }
}