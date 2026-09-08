//
//  InputBarAttachmentPreview.swift
//  TestOnboardingChat
//

import Foundation

enum InputBarAttachmentPreview: Identifiable, Equatable {
    case media(assets: [AddedMediaAsset], selectedIndex: Int)
    case file(URL)

    var id: String {
        switch self {
        case .media(let assets, let selectedIndex):
            "media-\(assets[selectedIndex].id)"
        case .file(let url):
            "file-\(url.absoluteString)"
        }
    }

    static func mediaPreview(
        assets: [InputBarAsset],
        tappedAsset: AddedMediaAsset
    ) -> InputBarAttachmentPreview? {
        let mediaAssets = assets.compactMap { asset -> AddedMediaAsset? in
            if case .media(let media) = asset {
                return media
            }
            return nil
        }
        guard let selectedIndex = mediaAssets.firstIndex(where: { $0.id == tappedAsset.id }) else {
            return nil
        }
        return .media(assets: mediaAssets, selectedIndex: selectedIndex)
    }
}
