import AVKit
import KindlingCore
import KindlingUI
import SwiftUI

struct MemoryMediaView: View {
    let reference: MediaReference?
    var height: CGFloat = 220
    var showsPlayback = false

    @State private var image: UIImage?

    var body: some View {
        Group {
            if showsPlayback,
               reference?.mediaType == .video,
               let path = reference?.importedFileRelativePath,
               let url = try? MemoryFileStore.URL(forRelativePath: path, in: .media) {
                VideoPlayer(player: AVPlayer(url: url))
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .background(KindlingColor.surface)
        .task(id: imageSourceID) { loadImage() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [KindlingColor.surfaceStrong, KindlingColor.glow.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(KindlingColor.accent)
        }
    }

    private var imagePath: String? {
        guard let reference else { return nil }
        if reference.mediaType == .video { return reference.posterFileRelativePath }
        return reference.importedFileRelativePath
    }

    private var imageSourceID: String? {
        reference?.bundledAssetName ?? imagePath
    }

    private var accessibilityLabel: String {
        guard let reference else { return "Decorative sample memory illustration" }
        return reference.mediaType == .video ? "Video memory" : "Photo memory"
    }

    private func loadImage() {
        if let assetName = reference?.bundledAssetName {
            image = UIImage(named: assetName)
            return
        }
        guard let imagePath else { image = nil; return }
        let directory: MemoryFileStore.Directory = reference?.mediaType == .video ? .thumbnails : .media
        guard let url = try? MemoryFileStore.URL(forRelativePath: imagePath, in: directory),
              let loaded = UIImage(contentsOfFile: url.path)
        else { image = nil; return }
        image = loaded
    }
}
