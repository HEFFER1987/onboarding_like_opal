//
//  InputBarViewModel+Recording.swift
//  TestOnboardingChat
//

import AVFoundation
import CoreGraphics
import Foundation
import UIKit

extension InputBarViewModel {
    func showRecordingTip() {
        let saveHint = config.isVoiceRecordingAutoSendEnabled
            ? "Hold the microphone button to record a voice message."
            : "Hold the microphone button to record. Release to save, or swipe up to lock."
        recordingSnackBarText = saveHint
    }

    func startRecording() {
        guard recordingState == .recording else { return }
        guard !voiceRecordingService.isRecording else { return }
        isRecordingPaused = false
        voiceRecordingService.onMeteringUpdate = { [weak self] power, duration in
            guard let self else { return }
            if let power {
                self.audioRecordingInfo.update(with: power, duration: duration)
            } else {
                self.audioRecordingInfo.updateDuration(duration)
            }
        }
        voiceRecordingService.onFinish = { [weak self] url, duration, waveform in
            self?.handleRecordingFinished(url: url, duration: duration, waveform: waveform)
        }
        voiceRecordingService.onError = { [weak self] in
            self?.recordingSnackBarText = "Microphone access is required to record voice messages."
            self?.discardRecording()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        voiceRecordingService.startRecording()
    }

    func stopRecording() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isRecordingPaused = false
        voiceRecordingService.stopRecording()
    }

    func toggleRecordingPause() {
        guard recordingState == .recording || recordingState == .locked else { return }

        if voiceRecordingService.isRecording {
            pauseRecording()
        } else if voiceRecordingService.hasActiveSession {
            resumeRecording()
        }
    }

    func pauseRecording() {
        guard voiceRecordingService.isRecording else { return }
        voiceRecordingService.pauseRecording()
        isRecordingPaused = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func resumeRecording() {
        guard isRecordingPaused, voiceRecordingService.isPaused else { return }
        voiceRecordingService.resumeRecording()
        isRecordingPaused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func sendRecording() {
        guard recordingState == .recording else { return }
        shouldSendOnRecordingFinish = true
        stopRecording()
    }

    func saveRecording() {
        guard recordingState == .recording else { return }
        shouldSendOnRecordingFinish = false
        stopRecording()
        resetRecordingUIIfRecordingDidNotFinish()
    }

    func discardRecording() {
        shouldSendOnRecordingFinish = false
        stopPreviewPlaybackIfNeeded()

        if let pending = pendingAudioRecording {
            try? FileManager.default.removeItem(at: pending.url)
            pendingVoiceRecordings.removeAll { $0.id == pending.id }
        }

        voiceRecordingService.cancelRecording()
        isRecordingPaused = false
        recordingState = .initial
        audioRecordingInfo = .initial
        recordingGestureLocation = .zero
        pendingAudioRecording = nil
    }

    func confirmRecording() {
        if recordingState == .stopped {
            stopPreviewPlaybackIfNeeded()
            if let pending = pendingAudioRecording {
                pendingVoiceRecordings.append(pending)
                pendingAudioRecording = nil
            }
            audioRecordingInfo = .initial
            recordingState = .initial
            return
        }

        shouldSendOnRecordingFinish = false
        stopRecording()
        finishRecordingUIIfNeeded()
    }

    func previewRecording() {
        shouldSendOnRecordingFinish = false
        recordingState = .stopped
        stopRecording()
    }

    func stopPreviewPlaybackIfNeeded() {
        guard let pending = pendingAudioRecording else { return }
        guard voicePlayback.isActive(url: pending.url) else { return }
        voicePlayback.stop()
    }

    private func handleRecordingFinished(url: URL, duration: TimeInterval, waveform: [Float]) {
        let resolvedDuration = resolvedRecordingDuration(url: url, reportedDuration: duration)

        guard resolvedDuration > 0.1 else {
            try? FileManager.default.removeItem(at: url)
            recordingState = .initial
            audioRecordingInfo = .initial
            recordingGestureLocation = .zero
            pendingAudioRecording = nil
            shouldSendOnRecordingFinish = false
            isRecordingPaused = false
            return
        }

        let samples = waveform.isEmpty ? Array(repeating: Float(0.25), count: 20) : waveform
        let recording = InputBarVoiceRecording(url: url, duration: resolvedDuration, waveform: samples)

        if recordingState == .stopped {
            pendingAudioRecording = recording
            audioRecordingInfo.waveform = samples
            audioRecordingInfo.duration = resolvedDuration
        } else {
            pendingVoiceRecordings.append(recording)
            recordingState = .initial
            audioRecordingInfo = .initial
            recordingGestureLocation = .zero
            pendingAudioRecording = nil
            isRecordingPaused = false

            if shouldSendOnRecordingFinish {
                shouldSendOnRecordingFinish = false
                onVoiceRecordingAutoSend?()
            }
        }
    }

    private func resolvedRecordingDuration(url: URL, reportedDuration: TimeInterval) -> TimeInterval {
        var resolved = max(reportedDuration, audioRecordingInfo.duration)
        let assetDuration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
        if assetDuration.isFinite {
            resolved = max(resolved, assetDuration)
        }
        return resolved
    }

    private func resetRecordingUIIfRecordingDidNotFinish() {
        finishRecordingUIIfNeeded()
    }

    private func finishRecordingUIIfNeeded() {
        guard recordingState != .initial else { return }
        recordingState = .initial
        audioRecordingInfo = .initial
        recordingGestureLocation = .zero
        isRecordingPaused = false
    }
}
