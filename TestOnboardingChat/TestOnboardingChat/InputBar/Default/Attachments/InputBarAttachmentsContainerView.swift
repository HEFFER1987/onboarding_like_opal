//
//  InputBarAttachmentsContainerView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarAttachmentsContainerView: View {
    @Environment(\.layoutDirection) private var layoutDirection

    var assets: [InputBarAsset]
    var onDiscardAttachment: (String) -> Void

    @State private var mediaPreview: InputBarAttachmentPreview?
    @State private var filePreview: FilePreviewItem?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: 0, height: 0).id(headId)
                    HStack(spacing: 6) {
                        ForEach(displayedAssets) { asset in
                            assetView(for: asset)
                                .padding(2)
                                .id(asset.id)
                        }
                    }
                    Color.clear.frame(width: 0, height: 0).id(tailId)
                }
                .padding(.trailing, 6)
            }
            .onChange(of: assets.count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        proxy.scrollTo(scrollTargetAnchorId, anchor: .trailing)
                    }
                }
            }
        }
        .fullScreenCover(item: $mediaPreview) { preview in
            if case .media(let mediaAssets, let selectedIndex) = preview {
                InputBarMediaPreviewView(assets: mediaAssets, selectedIndex: selectedIndex)
            }
        }
        .sheet(item: $filePreview) { item in
            InputBarFilePreviewView(url: item.url)
        }
    }

    private var displayedAssets: [InputBarAsset] {
        layoutDirection == .rightToLeft ? assets.reversed() : assets
    }

    private var scrollTargetAnchorId: String {
        layoutDirection == .rightToLeft ? headId : tailId
    }

    private let headId = "composer-tray-head"
    private let tailId = "composer-tray-tail"

    @ViewBuilder
    private func assetView(for asset: InputBarAsset) -> some View {
        switch asset {
        case .media(let attachment):
            switch attachment.type {
            case .video:
                InputBarVideoAttachmentView(
                    attachment: attachment,
                    onDiscard: onDiscardAttachment,
                    onOpen: { openMediaPreview(for: attachment) }
                )
            case .image:
                InputBarImageAttachmentView(
                    attachment: attachment,
                    onDiscard: onDiscardAttachment,
                    onOpen: { openMediaPreview(for: attachment) }
                )
            }
        case .file(let url):
            InputBarFileAttachmentView(
                url: url,
                onDiscard: onDiscardAttachment,
                onOpen: { filePreview = FilePreviewItem(url: url) }
            )
        }
    }

    private func openMediaPreview(for attachment: AddedMediaAsset) {
        mediaPreview = InputBarAttachmentPreview.mediaPreview(
            assets: assets,
            tappedAsset: attachment
        )
    }
}

private struct FilePreviewItem: Identifiable {
    let id: String
    let url: URL

    init(url: URL) {
        self.url = url
        id = url.absoluteString
    }
}
