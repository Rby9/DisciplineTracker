import Foundation
import UIKit

enum ProfileAvatarStore {
    private static let fileName = "profile-avatar.jpg"
    private static let sourceFileName = "profile-avatar-source.jpg"

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func loadSource() -> UIImage? {
        guard let data = try? Data(contentsOf: sourceFileURL) else { return load() }
        return UIImage(data: data)
    }

    static func saveSource(_ data: Data) throws -> UIImage {
        guard let source = UIImage(data: data) else {
            throw AvatarError.invalidImage
        }
        let normalized = resized(source, maximumDimension: 1600)
        try write(normalized, to: sourceFileURL, quality: 0.9)
        return normalized
    }

    static func save(_ data: Data) throws -> UIImage {
        guard let source = UIImage(data: data) else {
            throw AvatarError.invalidImage
        }

        let targetSize = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            let scale = max(
                targetSize.width / source.size.width,
                targetSize.height / source.size.height
            )
            let size = CGSize(
                width: source.size.width * scale,
                height: source.size.height * scale
            )
            let origin = CGPoint(
                x: (targetSize.width - size.width) / 2,
                y: (targetSize.height - size.height) / 2
            )
            source.draw(in: CGRect(origin: origin, size: size))
        }

        guard let jpeg = thumbnail.jpegData(compressionQuality: 0.82) else {
            throw AvatarError.encodingFailed
        }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try jpeg.write(to: fileURL, options: .atomic)
        return thumbnail
    }

    static func saveOriginal(_ image: UIImage) throws -> UIImage {
        let resizedImage = resized(image, maximumDimension: 1024)
        try write(resizedImage, to: fileURL, quality: 0.86)
        return resizedImage
    }

    static func saveCrop(
        _ image: UIImage,
        zoom: CGFloat,
        offset: CGSize,
        viewport: CGFloat
    ) throws -> UIImage {
        let target: CGFloat = 512
        let baseScale = max(target / image.size.width, target / image.size.height)
        let appliedZoom = max(zoom, 1)
        let drawnSize = CGSize(
            width: image.size.width * baseScale * appliedZoom,
            height: image.size.height * baseScale * appliedZoom
        )
        let outputOffset = CGSize(
            width: offset.width * target / viewport,
            height: offset.height * target / viewport
        )
        let origin = CGPoint(
            x: (target - drawnSize.width) / 2 + outputOffset.width,
            y: (target - drawnSize.height) / 2 + outputOffset.height
        )
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target))
        let cropped = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: target, height: target))
            image.draw(in: CGRect(origin: origin, size: drawnSize))
        }
        try write(cropped, to: fileURL, quality: 0.86)
        return cropped
    }

    static func remove() throws {
        for url in [fileURL, sourceFileURL] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return directory.appendingPathComponent(fileName)
    }

    private static var sourceFileURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent(sourceFileName)
    }

    private static func resized(_ image: UIImage, maximumDimension: CGFloat) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maximumDimension else { return image }
        let ratio = maximumDimension / largest
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func write(_ image: UIImage, to url: URL, quality: CGFloat) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw AvatarError.encodingFailed
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    enum AvatarError: LocalizedError {
        case invalidImage
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage: String(localized: "The selected photo could not be read.")
            case .encodingFailed: String(localized: "The selected photo could not be saved.")
            }
        }
    }
}
