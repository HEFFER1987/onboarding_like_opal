//
//  AttachmentMediaPickerItemView.swift
//  TestOnboardingChat
//

import Photos
import SwiftUI

struct AttachmentMediaPickerItemView: View {
    @StateObject private var handler: MediaPickerAssetHandler

    var asset: PHAsset
    var onImageTap: (AddedMediaAsset) -> Void
    var imageSelected: (String) -> Bool
    var selectedAssetIds: Set<String>?

    init(
        assetLoader: PhotoAssetLoader,
        asset: PHAsset,
        onImageTap: @escaping (AddedMediaAsset) -> Void,
        imageSelected: @escaping (String) -> Bool,
        selectedAssetIds: Set<String>? = nil
    ) {
        _handler = StateObject(wrappedValue: MediaPickerAssetHandler(
            asset: asset,
            assetLoader: assetLoader
        ))
        self.asset = asset
        self.onImageTap = onImageTap
        self.imageSelected = imageSelected
        self.selectedAssetIds = selectedAssetIds
    }

    var body: some View {
        let selected = isAssetSelected(asset.localIdentifier)
        ZStack {
            if let image = handler.currentImage {
                GeometryReader { reader in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: reader.size.width, height: reader.size.height)
                            .allowsHitTesting(false)
                            .clipped()

                        Rectangle()
                            .fill(.clear)
                            .frame(width: reader.size.width, height: reader.size.height)
                            .contentShape(.rect)
                            .clipped()
                            .onTapGesture {
                                handler.handleTap(
                                    image: image,
                                    currentlySelected: selected,
                                    onSelect: onImageTap
                                )
                            }
                    }
                    .overlay {
                        if handler.isBusy {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
            } else {
                Color.white.opacity(0.08)
                    .aspectRatio(1, contentMode: .fill)

                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.25))
                }

                MediaPickerSelectionBadge(isSelected: selected)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                if asset.mediaType == .video {
                    MediaPickerVideoBadge(durationText: formattedDuration(asset.duration))
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .allowsHitTesting(false)
            .id(handler.overlayID)
        }
        .onAppear { handler.onAppear() }
        .onDisappear { handler.onDisappear() }
    }

    private func isAssetSelected(_ id: String) -> Bool {
        if let selectedAssetIds {
            return selectedAssetIds.contains(id)
        }
        return imageSelected(id)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        if seconds < 60 {
            return "\(seconds)s"
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct MediaPickerSelectionBadge: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.white.opacity(0.85))
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct MediaPickerVideoBadge: View {
    let durationText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.fill")
                .font(.system(size: 10))
            Text(durationText)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
    }
}
