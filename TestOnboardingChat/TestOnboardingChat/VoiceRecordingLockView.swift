//
//  VoiceRecordingLockView.swift
//  TestOnboardingChat
//

import SwiftUI

struct VoiceRecordingLockView: View {
    var dragLocation: CGPoint = .zero
    var isLocked: Bool = false

    private var lockProgress: CGFloat {
        if isLocked { return 1 }
        guard dragLocation.y < 0 else { return 0 }
        return min(1, -dragLocation.y / -VoiceRecordingConstants.lockMaxDistance)
    }

    private var lockSymbolName: String {
        isLocked || lockProgress >= 0.5 ? "lock" : "lock.open"
    }

    var body: some View {
        VStack(spacing: isLocked ? 0 : 4) {
            Image(systemName: lockSymbolName)
                .font(.system(size: 20))
                .contentTransition(.symbolEffect(.replace))

            Image(systemName: "chevron.up")
                .font(.system(size: 16))
                .opacity(isLocked ? 0 : 1)
                .frame(height: isLocked ? 0 : nil)
                .clipped()
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(10)
        .frame(width: 40)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
