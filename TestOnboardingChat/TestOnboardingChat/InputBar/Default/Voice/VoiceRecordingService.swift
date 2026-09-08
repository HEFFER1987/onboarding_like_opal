//
//  VoiceRecordingService.swift
//  TestOnboardingChat
//

import AVFoundation
import Foundation

@MainActor
final class VoiceRecordingService {
    var onMeteringUpdate: ((Float, TimeInterval) -> Void)?
    var onFinish: ((URL, TimeInterval, [Float]) -> Void)?
    var onError: (() -> Void)?

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var waveformSamples: [Float] = []
    private var recordingURL: URL?

    private var isPreparingRecording = false

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    func startRecording() {
        guard !isRecording, !isPreparingRecording else { return }
        isPreparingRecording = true
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                self.isPreparingRecording = false
                guard granted else {
                    self.onError?()
                    return
                }
                self.beginRecording()
            }
        }
    }

    private func beginRecording() {
        guard !isRecording else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            onError?()
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        recordingURL = url
        waveformSamples = []

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            startMetering()
        } catch {
            onError?()
        }
    }

    func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        isPreparingRecording = false
        guard let url = recordingURL else { return }
        let duration = recorder?.currentTime ?? 0
        let waveform = waveformSamples
        recorder?.stop()
        recorder = nil
        recordingURL = nil
        waveformSamples = []
        onFinish?(url, duration, waveform)
    }

    func cancelRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recorder = nil
        recordingURL = nil
        waveformSamples = []
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateMeters()
            }
        }
    }

    private func updateMeters() {
        guard let recorder else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = max(0.05, (power + 50) / 50)
        waveformSamples.append(normalized)
        onMeteringUpdate?(normalized, recorder.currentTime)
    }
}
