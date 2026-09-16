@preconcurrency import AVFoundation
import CoreTransferable
import CoreGraphics
import Foundation
import ImageIO
import KindlingCore
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PickedMediaFile: Transferable, Sendable {
    let url: URL
    let contentType: UTType

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            try copied(received.file, contentType: .image)
        }
        FileRepresentation(importedContentType: .movie) { received in
            try copied(received.file, contentType: .movie)
        }
    }

    private static func copied(_ source: URL, contentType: UTType) throws -> PickedMediaFile {
        let target = FileManager.default.temporaryDirectory
            .appending(path: "kindling-picker-\(UUID().uuidString)")
            .appendingPathExtension(source.pathExtension.isEmpty ? contentType.preferredFilenameExtension ?? "data" : source.pathExtension)
        try FileManager.default.copyItem(at: source, to: target)
        return PickedMediaFile(url: target, contentType: contentType)
    }
}

struct ProcessedMedia: Sendable {
    let id: UUID
    let stableIdentifier: String
    let relativePath: String
    let posterRelativePath: String?
    let mediaType: MemoryMediaType
    let creationDate: Date?
    let latitude: Double?
    let longitude: Double?
    let pixelWidth: Int?
    let pixelHeight: Int?
    let durationSeconds: Double?
    let fingerprint: String

    var clusteringMetadata: MemoryMediaMetadata {
        MemoryMediaMetadata(
            id: id,
            stableIdentifier: stableIdentifier,
            creationDate: creationDate,
            latitude: latitude,
            longitude: longitude
        )
    }
}

enum MediaImportError: Error {
    case noRepresentation
    case unsupportedType
    case imageDecodeFailed
    case videoExportFailed
}

struct MediaImportService: Sendable {
    func process(item: PhotosPickerItem, index: Int) async throws -> ProcessedMedia {
        try Task.checkCancellation()
        guard let received = try await item.loadTransferable(type: PickedMediaFile.self) else {
            throw MediaImportError.noRepresentation
        }
        defer { try? FileManager.default.removeItem(at: received.url) }
        let stableIdentifier = item.itemIdentifier ?? "selection-\(index)"
        if received.contentType.conforms(to: .movie) {
            return try await processVideo(received.url, stableIdentifier: stableIdentifier)
        }
        if received.contentType.conforms(to: .image) {
            return try await processImage(received.url, stableIdentifier: stableIdentifier)
        }
        throw MediaImportError.unsupportedType
    }

    private func processImage(_ source: URL, stableIdentifier: String) async throws -> ProcessedMedia {
        try await Task.detached(priority: .userInitiated) {
            guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
            else { throw MediaImportError.imageDecodeFailed }

            let id = UUID()
            let filename = id.uuidString + ".jpg"
            let output = try MemoryFileStore.URL(forRelativePath: filename, in: .media)
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2560
            ]
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary),
                  let destination = CGImageDestinationCreateWithURL(
                    output as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                  )
            else { throw MediaImportError.imageDecodeFailed }
            CGImageDestinationAddImage(destination, thumbnail, [
                kCGImageDestinationLossyCompressionQuality: 0.84
            ] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                throw MediaImportError.imageDecodeFailed
            }

            let gps = Self.gps(from: properties)
            let created = Self.creationDate(from: properties)
                ?? (try? source.resourceValues(forKeys: [.creationDateKey]).creationDate)
            let data = try Data(contentsOf: output, options: [.mappedIfSafe])
            return ProcessedMedia(
                id: id,
                stableIdentifier: stableIdentifier,
                relativePath: filename,
                posterRelativePath: nil,
                mediaType: .image,
                creationDate: created,
                latitude: gps?.latitude,
                longitude: gps?.longitude,
                pixelWidth: thumbnail.width,
                pixelHeight: thumbnail.height,
                durationSeconds: nil,
                fingerprint: Self.fingerprint(data)
            )
        }.value
    }

    private func processVideo(_ source: URL, stableIdentifier: String) async throws -> ProcessedMedia {
        let asset = AVURLAsset(url: source)
        let id = UUID()
        let filename = id.uuidString + ".mp4"
        let output = try MemoryFileStore.URL(forRelativePath: filename, in: .media)
        try await Self.exportVideo(asset: asset, to: output)

        let posterName = id.uuidString + ".jpg"
        let posterURL = try MemoryFileStore.URL(forRelativePath: posterName, in: .thumbnails)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let frame = try? generator.copyCGImage(at: .zero, actualTime: nil),
           let destination = CGImageDestinationCreateWithURL(
            posterURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
           ) {
            CGImageDestinationAddImage(destination, frame, [
                kCGImageDestinationLossyCompressionQuality: 0.8
            ] as CFDictionary)
            _ = CGImageDestinationFinalize(destination)
        }

        let duration = try? await asset.load(.duration)
        let naturalSize: CGSize? = try? await asset.loadTracks(withMediaType: .video).first?.load(.naturalSize)
        let creationMetadata = try? await asset.load(.creationDate)
        let created: Date? = if let creationMetadata {
            try? await creationMetadata.load(.dateValue)
        } else {
            nil
        }
        let data = try Data(contentsOf: output, options: [.mappedIfSafe])
        return ProcessedMedia(
            id: id,
            stableIdentifier: stableIdentifier,
            relativePath: filename,
            posterRelativePath: FileManager.default.fileExists(atPath: posterURL.path) ? posterName : nil,
            mediaType: .video,
            creationDate: created,
            latitude: nil,
            longitude: nil,
            pixelWidth: naturalSize.map { Int(abs($0.width)) },
            pixelHeight: naturalSize.map { Int(abs($0.height)) },
            durationSeconds: duration.map(CMTimeGetSeconds),
            fingerprint: Self.fingerprint(data)
        )
    }

    private static func exportVideo(asset: AVAsset, to output: URL) async throws {
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1920x1080
        ) else { throw MediaImportError.videoExportFailed }
        session.outputURL = output
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        await session.export()
        guard session.status == .completed else {
            try? FileManager.default.removeItem(at: output)
            throw session.error ?? MediaImportError.videoExportFailed
        }
    }

    private static func creationDate(from properties: [CFString: Any]) -> Date? {
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let raw = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? properties[kCGImagePropertyTIFFDictionary]
                .flatMap { $0 as? [CFString: Any] }?[kCGImagePropertyTIFFDateTime] as? String
        guard let raw else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: raw)
    }

    private static func gps(from properties: [CFString: Any]) -> (latitude: Double, longitude: Double)? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double
        else { return nil }
        if (gps[kCGImagePropertyGPSLatitudeRef] as? String)?.uppercased() == "S" { latitude *= -1 }
        if (gps[kCGImagePropertyGPSLongitudeRef] as? String)?.uppercased() == "W" { longitude *= -1 }
        return (latitude, longitude)
    }

    private static func fingerprint(_ data: Data) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data.prefix(64 * 1024) {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
