//
//  DismissButtonOverlayModifier.swift
//  TestOnboardingChat
//

import SwiftUI

struct DismissButtonOverlayModifier: ViewModifier {
    @Environment(\.layoutDirection) private var layoutDirection

    let onDismiss: () -> Void

    private let overlap: CGFloat = 4

    func body(content: Content) -> some View {
        content.overlay(dismissButton, alignment: .topTrailing)
    }

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.black.opacity(0.65))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .offset(x: horizontalOffset, y: -overlap)
        .accessibilityLabel("Remove attachment")
    }

    private var horizontalOffset: CGFloat {
        layoutDirection == .rightToLeft ? -overlap : overlap
    }
}

extension View {
    func dismissButtonOverlay(onDismiss: @escaping () -> Void) -> some View {
        modifier(DismissButtonOverlayModifier(onDismiss: onDismiss))
    }
}
