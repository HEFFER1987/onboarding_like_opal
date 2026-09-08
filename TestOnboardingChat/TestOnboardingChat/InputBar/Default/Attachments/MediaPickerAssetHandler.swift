//
//  MediaPickerAssetHandler.swift
//  TestOnboardingChat
//

import Combine
import Photos
import SwiftUI

@MainActor
final class MediaPickerAssetHandler: ObservableObject {
    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var loading = false
    @Published private(set) var compressing = false
    @Published private(set) var overlayID = UUID()

    private(set) var requestId: PHImageRequestID?
    private(set) var assetURL: URL?

    private let asset: PHAsset
    private let assetLoader: PhotoAssetLoader
    private var requestToken: UUID?

    var assetType: InputBarAssetType {
        asset.mediaType == .video ? .video : .image
    }

    var isBusy: Bool {
        loading || compressing
    }

    var currentImage: UIImage? {
        thumbnail ?? assetLoader.cachedImage(for: asset)
    }

    init(asset: PHAsset, assetLoader: PhotoAssetLoader) {
        self.asset = asset
        self.assetLoader = assetLoader
    }

    func onAppear() {
        loadThumbnail()
    }

    func onDisappear() {
        assetLoader.cancelImageLoad(for: asset)
        cancelAssetURLRequest()
        thumbnail = nil
    }

    func handleTap(
        image: UIImage,
        currentlySelected: Bool,
        onSelect: @escaping (AddedMediaAsset) -> Void
    ) {
        if currentlySelected || assetURL != nil {
            guard !compressing else { return }
            withAnimation {
                selectAsset(image: image, currentlySelected: currentlySelected, onSelect: onSelect)
            }
            return
        }

        guard !loading, !compressing, requestId == nil else { return }

        resolveAssetURL {
            guard self.assetURL != nil else { return }
            withAnimation {
                self.selectAsset(image: image, currentlySelected: false, onSelect: onSelect)
            }
        }
    }

    private func loadThumbnail() {
        guard thumbnail == nil, assetLoader.cachedImage(for: asset) == nil else { return }
        assetLoader.loadImage(for: asset, targetSize: CGSize(width: 250, height: 250)) { [weak self] image in
            self?.thumbnail = image
        }
    }

    private func resolveAssetURL(completion: @escaping () -> Void) {
        cancelAssetURLRequest()

        requestAssetURL(allowsNetworkAccess: false) { [weak self] url in
            guard let self else { return }
            if let url {
                assetURL = url
                compressVideoIfNeeded(completion: completion)
            } else {
                downloadAssetURL(completion: completion)
            }
        }
    }

    private func downloadAssetURL(completion: @escaping () -> Void) {
        loading = true

        requestAssetURL(allowsNetworkAccess: true) { [weak self] url in
            guard let self else { return }
            assetURL = url
            compressVideoIfNeeded {
                self.loading = false
                completion()
            }
        }
    }

    private func requestAssetURL(
        allowsNetworkAccess: Bool,
        completion: @escaping (URL?) -> Void
    ) {
        let token = UUID()
        requestToken = token
        let newRequestId = assetLoader.requestAssetURL(
            for: asset,
            allowsNetworkAccess: allowsNetworkAccess
        ) { [weak self] url in
            if let self, requestToken == token {
                requestId = nil
                requestToken = nil
            }
            completion(url)
        }
        if requestToken == token {
            requestId = newRequestId
        }
    }

    private func compressVideoIfNeeded(completion: @escaping () -> Void) {
        guard assetType == .video,
              let assetURL,
              assetLoader.assetExceedsAllowedSize(url: assetURL) else {
            completion()
            return
        }
        compressing = true
        assetLoader.compressAsset(at: assetURL, type: assetType) { [weak self] url in
            guard let self else { return }
            if let url {
                self.assetURL = url
            }
            compressing = false
            completion()
        }
    }

    private func cancelAssetURLRequest() {
        if let requestId {
            assetLoader.cancelRequest(requestId)
            self.requestId = nil
        }
        requestToken = nil
        loading = false
    }

    private func selectAsset(
        image: UIImage,
        currentlySelected: Bool,
        onSelect: @escaping (AddedMediaAsset) -> Void
    ) {
        let url = assetURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let duration = assetType == .video ? asset.duration : nil
        onSelect(
            AddedMediaAsset(
                id: asset.localIdentifier,
                url: url,
                type: assetType,
                image: image,
                duration: duration
            )
        )
        overlayID = UUID()
    }
}
