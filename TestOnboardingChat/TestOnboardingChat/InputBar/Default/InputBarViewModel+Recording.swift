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
        recordingSnackBarText = "Hold the microphone button to record a voice message."
    }

    func startRecording() {
        guard recordingState == .recording else { return }
        guard !voiceRecordingService.isRecording else { return }
        voiceRecordingService.onMeteringUpdate = { [weak self] power, duration in
            self?.audioRecordingInfo.update(with: power, duration: duration)
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
        voiceRecordingService.stopRecording()
    }

    func sendRecording() {
        guard recordingState == .recording else { return }
        stopRecording()
    }

    func saveRecording() {
        guard recordingState == .recording else { return }
        stopRecording()
        resetRecordingUIIfRecordingDidNotFinish()
    }

    func discardRecording() {
        let wasRecording = recordingState != .initial
        if let pending = pendingAudioRecording {
            pendingVoiceRecordings.removeAll { $0.id == pending.id }
        }
        voiceRecordingService.cancelRecording()
        recordingState = .initial
        audioRecordingInfo = .initial
        recordingGestureLocation = .zero
        pendingAudioRecording = nil
        if wasRecording, recordingSnackBarText == nil {
            recordingSnackBarText = "Voice message deleted."
        }
    }

    func confirmRecording() {
        if recordingState == .stopped {
            pendingAudioRecording = nil
            audioRecordingInfo = .initial
            recordingState = .initial
            return
        }

        stopRecording()
        finishRecordingUIIfNeeded()
    }

    func previewRecording() {
        recordingState = .stopped
        stopRecording()
    }

    private func handleRecordingFinished(url: URL, duration: TimeInterval, waveform: [Float]) {
        let resolvedDuration = resolvedRecordingDuration(url: url, reportedDuration: duration)

        guard resolvedDuration > 0.1 else {
            try? FileManager.default.removeItem(at: url)
            recordingState = .initial
            audioRecordingInfo = .initial
            recordingGestureLocation = .zero
            pendingAudioRecording = nil
            return
        }

        let samples = waveform.isEmpty ? Array(repeating: Float(0.25), count: 20) : waveform
        let recording = InputBarVoiceRecording(url: url, duration: resolvedDuration, waveform: samples)
        pendingVoiceRecordings.append(recording)

        if recordingState == .stopped {
            pendingAudioRecording = recording
            audioRecordingInfo.waveform = samples
            audioRecordingInfo.duration = resolvedDuration
        } else {
            recordingState = .initial
            audioRecordingInfo = .initial
            recordingGestureLocation = .zero
            pendingAudioRecording = nil
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
    }
}
