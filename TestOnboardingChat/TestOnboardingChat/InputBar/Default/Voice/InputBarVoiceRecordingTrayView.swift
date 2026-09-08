//
//  InputBarVoiceRecordingTrayView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarVoiceRecordingTrayView: View {
    var recordings: [InputBarVoiceRecording]
    @Bindable var playback: VoiceRecordingPlaybackService
    var onRemove: (String) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(recordings) { recording in
                InputBarVoiceRecordingAttachmentView(
                    recording: recording,
                    playback: playback,
                    onDiscard: onRemove
                )
            }
        }
    }
}

struct InputBarVoiceRecordingAttachmentView: View {
    let recording: InputBarVoiceRecording
    @Bindable var playback: VoiceRecordingPlaybackService
    let onDiscard: (String) -> Void

    private var isActive: Bool {
        playback.isActive(url: recording.url)
    }

    private var isPlaying: Bool {
        isActive && playback.isPlaying
    }

    private var progress: Double {
        guard recording.duration > 0 else { return 0 }
        if isActive {
            return min(1, playback.currentTime / recording.duration)
        }
        return 0
    }

    private var displayedDuration: TimeInterval {
        if isActive && playback.isPlaying {
            return playback.currentTime
        }
        return recording.duration
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                playback.togglePlayback(for: recording.url)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text(formattedDuration(displayedDuration))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 36, alignment: .leading)

                InputBarVoiceWaveformView(
                    waveform: recording.waveform,
                    progress: progress
                )
                .frame(height: 24)
            }
            .frame(maxWidth: .infinity)

            Button {
                playback.cyclePlaybackRate()
            } label: {
                Text(playbackRateLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 32)
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 1 : 0.45)
            .disabled(!isActive)
        }
        .padding(.horizontal, 12)
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .dismissButtonOverlay {
            if playback.isActive(url: recording.url) {
                playback.stop()
            }
            onDiscard(recording.id)
        }
    }

    private var playbackRateLabel: String {
        switch playback.playbackRate {
        case 1.5:
            return "1.5x"
        case 2.0:
            return "2x"
        default:
            return "1x"
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
