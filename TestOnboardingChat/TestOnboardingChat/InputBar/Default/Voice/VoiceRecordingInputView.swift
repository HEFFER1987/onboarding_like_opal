//
//  VoiceRecordingInputView.swift
//  TestOnboardingChat
//

import SwiftUI

struct VoiceRecordingInputView: View {
    var recordingState: VoiceRecordingState
    var isRecordingPaused: Bool
    var audioRecordingInfo: AudioRecordingInfo
    var pendingAudioRecordingURL: URL?
    var gestureLocation: CGPoint
    @Bindable var playback: VoiceRecordingPlaybackService
    var toggleRecordingPause: () -> Void
    var confirmRecording: () -> Void
    var discardRecording: () -> Void

    private let controlButtonSize: CGFloat = 36
    private let secondaryFill = Color.white.opacity(0.12)
    private let confirmFill = Color.white.opacity(0.85)

    private var isLockedOrStopped: Bool {
        recordingState.isLockedOrStopped
    }

    private var isStopped: Bool {
        recordingState == .stopped
    }

    var body: some View {
        VStack(spacing: 0) {
            recordingBar
            recordingControls
                .frame(height: isLockedOrStopped ? 48 : 0, alignment: .top)
                .clipped()
        }
        .animation(nil, value: isLockedOrStopped)
    }

    private var recordingBar: some View {
        HStack(spacing: 8) {
            recordingIndicator

            Text(formattedDuration(displayedDuration))
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundStyle(isStopped && isPreviewPlaying ? .red : .white)
                .fixedSize()

            ZStack(alignment: .trailing) {
                waveformPreview
                    .opacity(isLockedOrStopped ? 1 : 0)
                    .allowsHitTesting(false)

                if !isLockedOrStopped {
                    activeRecordingTrailing
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.trailing, isLockedOrStopped ? 12 : 0)
        .frame(height: 48)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
        .animation(nil, value: isLockedOrStopped)
    }

    private var recordingIndicator: some View {
        Image(systemName: isRecordingPaused ? "mic.slash" : "mic")
            .font(.system(size: 20))
            .foregroundStyle(isRecordingPaused ? .white.opacity(0.5) : .red)
            .frame(width: 48, height: 48)
            .accessibilityLabel(isRecordingPaused ? "Recording paused" : "Recording")
    }

    private var activeRecordingTrailing: some View {
        slideToCancel
            .opacity(opacityForSlideToCancel)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recordingPauseButton: some View {
        recordingControlButton(
            systemName: isRecordingPaused ? "record.circle.fill" : "pause.fill",
            iconSize: isRecordingPaused ? 18 : 14,
            foreground: .red,
            fill: secondaryFill,
            accessibilityLabel: isRecordingPaused ? "Resume recording" : "Pause recording",
            action: toggleRecordingPause
        )
    }

    private var discardButton: some View {
        recordingControlButton(
            systemName: "trash",
            iconSize: 18,
            foreground: .white.opacity(0.85),
            fill: secondaryFill,
            accessibilityLabel: "Delete recording",
            action: discardRecording
        )
    }

    private var confirmButton: some View {
        recordingControlButton(
            systemName: "checkmark",
            iconSize: 18,
            foreground: .black,
            fill: confirmFill,
            accessibilityLabel: "Confirm recording",
            action: confirmRecording
        )
    }

    private func recordingControlButton(
        systemName: String,
        iconSize: CGFloat,
        foreground: Color,
        fill: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: controlButtonSize, height: controlButtonSize)
                .background(Circle().fill(fill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var slideToCancel: some View {
        HStack(spacing: 4) {
            Text("Slide to cancel")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Image(systemName: "chevron.left")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .offset(x: min(0, gestureLocation.x))
        .padding(.trailing, 12)
    }

    private var waveformPreview: some View {
        InputBarVoiceWaveformView(
            waveform: audioRecordingInfo.waveform,
            progress: waveformProgress,
            isLiveRecording: recordingState == .locked
        )
        .frame(height: 24)
        .frame(maxWidth: .infinity)
        .transaction { $0.animation = nil }
    }

    private var waveformProgress: Double {
        guard isStopped, let url = pendingAudioRecordingURL, playback.isActive(url: url) else {
            return 1
        }
        guard audioRecordingInfo.duration > 0 else { return 0 }
        return min(1, playback.currentTime / audioRecordingInfo.duration)
    }

    private var recordingControls: some View {
        HStack(alignment: .center, spacing: 0) {
            discardButton

            if recordingState == .locked {
                Spacer(minLength: 0)
                recordingPauseButton
            }

            Spacer(minLength: 0)
            confirmButton
        }
        .frame(height: 48)
    }

    private var isPreviewPlaying: Bool {
        guard let url = pendingAudioRecordingURL else { return false }
        return playback.isActive(url: url) && playback.isPlaying
    }

    private var displayedDuration: TimeInterval {
        if isStopped, let url = pendingAudioRecordingURL {
            return playback.displayedTime(for: url, duration: audioRecordingInfo.duration)
        }
        return audioRecordingInfo.duration
    }

    private var opacityForSlideToCancel: CGFloat {
        guard gestureLocation.x < VoiceRecordingConstants.cancelMinDistance else { return 1 }
        return 1 - gestureLocation.x / VoiceRecordingConstants.cancelMaxDistance
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
