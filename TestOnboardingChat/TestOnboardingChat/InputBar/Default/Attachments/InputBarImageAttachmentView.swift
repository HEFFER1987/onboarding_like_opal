//
//  InputBarImageAttachmentView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarImageAttachmentView: View {
    private let imageSize: CGFloat = 72

    let attachment: AddedMediaAsset
    let onDiscard: (String) -> Void
    var onOpen: () -> Void = {}

    var body: some View {
        Button(action: onOpen) {
            Image(uiImage: attachment.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .id(attachment.id)
        .accessibilityLabel("Open attachment")
        .dismissButtonOverlay {
            onDiscard(attachment.id)
        }
    }
}
