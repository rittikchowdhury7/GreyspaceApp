//
//  ImageAttachment.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-08.
//


// ImageAttachment.swift
import Foundation
import SwiftData

@Model
final class ImageAttachment: Identifiable, Hashable {
    @Attribute(.unique) var id: String
    var filename: String          // relative in our app folder
    var createdAt: Date

    init(id: String = UUID().uuidString, filename: String, createdAt: Date = .now) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
    }
}
