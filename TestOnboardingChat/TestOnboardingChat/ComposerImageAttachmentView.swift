//
//  ComposerImageAttachmentView.swift
//  TestOnboardingChat
//

import SwiftUI

struct ComposerImageAttachmentView: View {
    private let imageSize: CGFloat = 72

    let attachment: AddedMediaAsset
    let onDiscard: (String) -> Void

    var body: some View {
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
            .id(attachment.id)
            .dismissButtonOverlay {
                onDiscard(attachment.id)
            }
    }
}
