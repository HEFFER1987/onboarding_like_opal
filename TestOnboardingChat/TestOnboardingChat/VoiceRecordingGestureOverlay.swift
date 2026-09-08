//
//  VoiceRecordingGestureOverlay.swift
//  TestOnboardingChat
//

import SwiftUI

struct VoiceRecordingGestureOverlay: View {
    @Environment(\.layoutDirection) private var layoutDirection

    @Binding var recordingState: VoiceRecordingState
    @Binding var gestureLocation: CGPoint

    var onRecordingStarted: () -> Void
    var onGestureCompleted: () -> Void
    var onRecordingReleased: () -> Void
    var onRecordingCancelled: () -> Void
    var onShortTapDetected: () -> Void

    @State private var longPressed = false
    @State private var longPressStarted: Date?
    @State private var recordingStartTask: DispatchWorkItem?

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(
                width: recordingState.isRecording ? nil : 48,
                height: 48
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let translation = normalizedTranslation(for: value.translation)
                        if !longPressed {
                            longPressStarted = Date()
                            longPressed = true
                            let work = DispatchWorkItem {
                                guard longPressed else { return }
                                recordingState = .recording
                                onRecordingStarted()
                                gestureLocation = translation
                            }
                            recordingStartTask?.cancel()
                            recordingStartTask = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
                        } else if recordingState.isRecording {
                            gestureLocation = translation
                        }
                    }
                    .onEnded { _ in
                        recordingStartTask?.cancel()
                        recordingStartTask = nil
                        longPressed = false
                        if recordingState != .recording && recordingState != .locked,
                           let longPressStarted,
                           Date().timeIntervalSince(longPressStarted) <= 1 {
                            onShortTapDetected()
                            self.longPressStarted = nil
                            return
                        }
                        if recordingState.isRecording {
                            if gestureLocation.x < VoiceRecordingConstants.cancelMinDistance {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    onRecordingCancelled()
                                }
                            } else {
                                onRecordingReleased()
                            }
                            gestureLocation = .zero
                        } else if recordingState != .locked {
                            onGestureCompleted()
                        }
                    }
            )
            .onDisappear {
                recordingStartTask?.cancel()
                recordingStartTask = nil
            }
    }

    private func normalizedTranslation(for translation: CGSize) -> CGPoint {
        let normalizedX = layoutDirection == .rightToLeft ? -translation.width : translation.width
        return CGPoint(x: normalizedX, y: translation.height)
    }
}
