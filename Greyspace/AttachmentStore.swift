//
//  AttachmentStore.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-09.
//


// AttachmentStore.swift
import UIKit

enum AttachmentStore {
    static let folderName = "Attachments"

    private static var baseURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static func save(image: UIImage, id: String = UUID().uuidString) throws -> String {
        // downscale + compress to keep storage sane
        let scaled = downscale(image, maxSide: 2000)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "AttachmentStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])
        }
        let name = "\(id).jpg"
        let url = baseURL.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return name // store relative filename in DB
    }

    static func load(filename: String) -> UIImage? {
        let url = baseURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(filename: String) {
        let url = baseURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    private static func downscale(_ img: UIImage, maxSide: CGFloat) -> UIImage {
        let size = img.size
        let scale = min(1, maxSide / max(size.width, size.height))
        guard scale < 1 else { return img }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
