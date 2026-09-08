//
//  AttachmentMediaPickerView.swift
//  TestOnboardingChat
//

import Photos
import SwiftUI

struct AttachmentMediaPickerView: View {
    @State private var assetLoader: PhotoAssetLoader

    var photoLibraryAssets: PHFetchResult<PHAsset>?
    var onImageTap: (AddedMediaAsset) -> Void
    var imageSelected: (String) -> Bool
    var selectedAssetIds: [String]?
    var isDisplayed: Bool
    var onRequestAccess: () -> Void

    private var selectedAssetIdsSet: Set<String>? {
        guard let selectedAssetIds else { return nil }
        return Set(selectedAssetIds)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    init(
        maxAttachmentSize: Int64 = 100 * 1024 * 1024,
        photoLibraryAssets: PHFetchResult<PHAsset>?,
        onImageTap: @escaping (AddedMediaAsset) -> Void,
        imageSelected: @escaping (String) -> Bool,
        selectedAssetIds: [String]? = nil,
        isDisplayed: Bool = false,
        onRequestAccess: @escaping () -> Void
    ) {
        _assetLoader = State(initialValue: PhotoAssetLoader(maxAttachmentSize: maxAttachmentSize))
        self.photoLibraryAssets = photoLibraryAssets
        self.onImageTap = onImageTap
        self.imageSelected = imageSelected
        self.selectedAssetIds = selectedAssetIds
        self.isDisplayed = isDisplayed
        self.onRequestAccess = onRequestAccess
    }

    var body: some View {
        Group {
            if let fetchResult = photoLibraryAssets {
                let collection = PHFetchResultCollection(fetchResult: fetchResult)
                if !collection.isEmpty {
                    assetGridContent(collection: collection)
                } else {
                    PhotoLibraryAccessPromptView(onRequestAccess: onRequestAccess)
                }
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func assetGridContent(collection: PHFetchResultCollection) -> some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<collection.count, id: \.self) { index in
                        let asset = collection[index]
                        AttachmentMediaPickerItemView(
                            assetLoader: assetLoader,
                            asset: asset,
                            onImageTap: onImageTap,
                            imageSelected: imageSelected,
                            selectedAssetIds: selectedAssetIdsSet
                        )
                        .id(asset.localIdentifier)
                    }
                }
            }
            .onChange(of: isDisplayed) { _, displayed in
                if displayed {
                    scrollView.scrollTo(0, anchor: .top)
                } else {
                    assetLoader.cancelAllImageLoads()
                }
            }
        }
    }
}

struct PhotoLibraryAccessPromptView: View {
    var onRequestAccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.5))
            Text("Allow access to your photo library to attach photos and videos.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Allow Access") {
                onRequestAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
