//
//  PhotoAssetLoader.swift
//  TestOnboardingChat
//

import AVFoundation
import Photos
import UIKit
import UniformTypeIdentifiers

@MainActor
final class PhotoAssetLoader {
    private let imageManager: PHImageManager
    private let maxAttachmentSize: Int64

    private let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    private var inFlightImageRequests = [String: PHImageRequestID]()

    init(imageManager: PHImageManager = .default(), maxAttachmentSize: Int64 = 100 * 1024 * 1024) {
        self.imageManager = imageManager
        self.maxAttachmentSize = maxAttachmentSize
    }

    func cachedImage(for asset: PHAsset) -> UIImage? {
        imageCache.object(forKey: asset.localIdentifier as NSString)
    }

    func cache(_ image: UIImage, for asset: PHAsset) {
        imageCache.setObject(
            image,
            forKey: asset.localIdentifier as NSString,
            cost: image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        )
    }

    func loadImage(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        if let cached = cachedImage(for: asset) {
            completion(cached)
            return
        }

        let assetId = asset.localIdentifier
        cancelImageLoad(for: asset)

        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        var isCompleted = false
        let requestId = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self, let image else { return }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !isDegraded {
                isCompleted = true
                inFlightImageRequests[assetId] = nil
                cache(image, for: asset)
            }
            completion(image)
        }
        if !isCompleted {
            inFlightImageRequests[assetId] = requestId
        }
    }

    func cancelImageLoad(for asset: PHAsset) {
        guard let requestId = inFlightImageRequests.removeValue(forKey: asset.localIdentifier) else { return }
        imageManager.cancelImageRequest(requestId)
    }

    func requestAssetURL(
        for asset: PHAsset,
        allowsNetworkAccess: Bool,
        completion: @escaping @MainActor (URL?) -> Void
    ) -> PHImageRequestID {
        asset.mediaType == .video
            ? requestVideoURL(for: asset, allowsNetworkAccess: allowsNetworkAccess, completion: completion)
            : requestImageURL(for: asset, allowsNetworkAccess: allowsNetworkAccess, completion: completion)
    }

    func cancelRequest(_ requestId: PHImageRequestID) {
        imageManager.cancelImageRequest(requestId)
    }

    func cancelAllImageLoads() {
        for requestId in inFlightImageRequests.values {
            imageManager.cancelImageRequest(requestId)
        }
        inFlightImageRequests.removeAll()
    }

    func assetExceedsAllowedSize(url: URL?) -> Bool {
        _ = url?.startAccessingSecurityScopedResource()
        guard let url,
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return false
        }
        return Int64(size) >= maxAttachmentSize
    }

    func compressAsset(at url: URL, type: InputBarAssetType, completion: @escaping @MainActor (URL?) -> Void) {
        guard type == .video else {
            completion(nil)
            return
        }
        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
        let urlAsset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            Task { @MainActor in
                completion(exportSession.status == .completed ? compressedURL : nil)
            }
        }
    }

    private func requestImageURL(
        for asset: PHAsset,
        allowsNetworkAccess: Bool,
        completion: @escaping @MainActor (URL?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = allowsNetworkAccess

        return imageManager.requestImageDataAndOrientation(for: asset, options: options) { @Sendable data, dataUTI, _, _ in
            Task { @MainActor in
                completion(data.flatMap { PhotoAssetLoader.temporaryJpgURL(for: $0, dataUTI: dataUTI) })
            }
        }
    }

    private func requestVideoURL(
        for asset: PHAsset,
        allowsNetworkAccess: Bool,
        completion: @escaping @MainActor (URL?) -> Void
    ) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = allowsNetworkAccess

        return imageManager.requestAVAsset(forVideo: asset, options: options) { @Sendable avAsset, _, _ in
            let url = (avAsset as? AVURLAsset)?.url
            Task { @MainActor in
                completion(url)
            }
        }
    }

    static func temporaryJpgURL(for data: Data, dataUTI: String?) -> URL? {
        if dataUTI == UTType.jpeg.identifier {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).jpg")
            do {
                try data.write(to: url)
                return url
            } catch {
                return nil
            }
        }
        return try? UIImage(data: data)?.saveAsJpgToTemporaryUrl()
    }
}

final class PHFetchResultCollection: RandomAccessCollection {
    typealias Element = PHAsset
    typealias Index = Int

    let fetchResult: PHFetchResult<PHAsset>

    var endIndex: Int { fetchResult.count }
    var startIndex: Int { 0 }

    init(fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: position)
    }
}

extension PHAsset: @retroactive Identifiable {
    public var id: String { localIdentifier }
}
