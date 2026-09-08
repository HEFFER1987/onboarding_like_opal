//
//  InputBarVideoAttachmentView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarVideoAttachmentView: View {
    let attachment: AddedMediaAsset
    let onDiscard: (String) -> Void
    var onOpen: () -> Void = {}

    var body: some View {
        InputBarImageAttachmentView(
            attachment: attachment,
            onDiscard: onDiscard,
            onOpen: onOpen
        )
        .mediaBadgeOverlay {
            InputBarVideoMediaBadge(durationText: formattedDuration)
        }
    }

    private var formattedDuration: String {
        guard let duration = attachment.duration else { return "0s" }
        let seconds = Int(duration.rounded())
        if seconds < 60 {
            return "\(seconds)s"
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct InputBarVideoMediaBadge: View {
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
        .background(Color.black.opacity(0.65))
        .clipShape(Capsule())
    }
}

struct MediaBadgeOverlayModifier<Badge: View>: ViewModifier {
    let badge: () -> Badge

    func body(content: Content) -> some View {
        content.overlay(
            VStack {
                Spacer()
                HStack {
                    badge()
                    Spacer()
                }
            }
            .padding(.leading, 4)
            .padding(.bottom, 4),
            alignment: .bottomLeading
        )
    }
}

extension View {
    func mediaBadgeOverlay<Badge: View>(@ViewBuilder badge: @escaping () -> Badge) -> some View {
        modifier(MediaBadgeOverlayModifier(badge: badge))
    }
}
