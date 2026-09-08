//
//  ComposerViewModel+Recording.swift
//  TestOnboardingChat
//

import CoreGraphics
import Foundation
import UIKit

extension ComposerViewModel {
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
    }

    func discardRecording() {
        let wasRecording = recordingState != .initial
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
        if recordingState == .stopped, let pending = pendingAudioRecording {
            pendingVoiceRecordings.append(pending)
            pendingAudioRecording = nil
            audioRecordingInfo = .initial
            recordingState = .initial
        } else {
            stopRecording()
        }
    }

    func previewRecording() {
        recordingState = .stopped
        stopRecording()
    }

    private func handleRecordingFinished(url: URL, duration: TimeInterval, waveform: [Float]) {
        Task { @MainActor in
            guard audioRecordingInfo != .initial || recordingState == .stopped else {
                try? FileManager.default.removeItem(at: url)
                recordingState = .initial
                audioRecordingInfo = .initial
                return
            }

            guard duration > 0.1 else {
                try? FileManager.default.removeItem(at: url)
                recordingState = .initial
                audioRecordingInfo = .initial
                return
            }

            let samples = waveform.isEmpty ? Array(repeating: Float(0.25), count: 20) : waveform
            let recording = ComposerVoiceRecording(url: url, duration: duration, waveform: samples)

            if recordingState == .stopped {
                pendingAudioRecording = recording
                audioRecordingInfo.waveform = samples
                audioRecordingInfo.duration = duration
            } else {
                pendingVoiceRecordings.append(recording)
                recordingState = .initial
                audioRecordingInfo = .initial
                recordingGestureLocation = .zero
            }
        }
    }
}
