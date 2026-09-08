//
//  VoiceRecordingInputView.swift
//  TestOnboardingChat
//

import SwiftUI

struct VoiceRecordingInputView: View {
    var recordingState: VoiceRecordingState
    var audioRecordingInfo: AudioRecordingInfo
    var pendingAudioRecordingURL: URL?
    var gestureLocation: CGPoint
    var stopRecording: () -> Void
    var confirmRecording: () -> Void
    var discardRecording: () -> Void
    var previewRecording: () -> Void

    @State private var isPlayingPreview = false

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
    }

    private var recordingBar: some View {
        HStack(spacing: 0) {
            if !isStopped {
                Image(systemName: "mic")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                    .frame(width: 48, height: 48)
            }

            Text(formattedDuration(isStopped ? (pendingAudioRecordingURL != nil ? audioRecordingInfo.duration : 0) : audioRecordingInfo.duration))
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)

            Spacer()

            if isLockedOrStopped {
                waveformPreview
            } else {
                slideToCancel
            }
        }
        .frame(height: 48)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
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
        HStack(spacing: 2) {
            ForEach(Array(audioRecordingInfo.waveform.suffix(30).enumerated()), id: \.offset) { _, sample in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 2, height: max(4, CGFloat(sample) * 20))
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 12)
    }

    private var recordingControls: some View {
        HStack {
            Button {
                discardRecording()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)

            Spacer()

            if recordingState == .locked {
                Button {
                    previewRecording()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                confirmRecording()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.85)))
            }
            .buttonStyle(.plain)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
