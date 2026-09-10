//
//  VoiceRecordingService.swift
//  TestOnboardingChat
//

import AVFoundation
import Foundation

@MainActor
final class VoiceRecordingService {
    var onMeteringUpdate: ((Float?, TimeInterval) -> Void)?
    var onFinish: ((URL, TimeInterval, [Float]) -> Void)?
    var onError: (() -> Void)?

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var waveformSamples: [Float] = []
    private var recordingURL: URL?
    private var pendingMeterLevels: [Float] = []
    private var lastBarAddedAt: TimeInterval = 0

    private let meterTickInterval: TimeInterval = 0.05
    private let barCaptureInterval: TimeInterval = 0.12

    private var isPreparingRecording = false

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    var hasActiveSession: Bool {
        recordingURL != nil
    }

    var isPaused: Bool {
        hasActiveSession && recorder?.isRecording == false
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
        pendingMeterLevels = []
        lastBarAddedAt = 0

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

    func pauseRecording() {
        guard let recorder, recorder.isRecording else { return }
        meterTimer?.invalidate()
        meterTimer = nil
        pendingMeterLevels = []
        recorder.pause()
    }

    func resumeRecording() {
        guard let recorder, hasActiveSession, !recorder.isRecording else { return }
        pendingMeterLevels = []
        lastBarAddedAt = recorder.currentTime
        recorder.record()
        startMetering()
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
        isPreparingRecording = false
        recorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recorder = nil
        recordingURL = nil
        waveformSamples = []
        pendingMeterLevels = []
        lastBarAddedAt = 0
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: meterTickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateMeters()
            }
        }
    }

    private func updateMeters() {
        guard let recorder else { return }
        recorder.updateMeters()
        let currentTime = recorder.currentTime
        let average = recorder.averagePower(forChannel: 0)
        let peak = recorder.peakPower(forChannel: 0)
        let power = max(average, peak)
        let normalized = normalizedMeterLevel(power: power)

        pendingMeterLevels.append(normalized)

        let shouldAddBar = lastBarAddedAt == 0
            || currentTime - lastBarAddedAt >= barCaptureInterval

        if shouldAddBar {
            let level = pendingMeterLevels.max() ?? normalized
            waveformSamples.append(level)
            pendingMeterLevels.removeAll(keepingCapacity: true)
            lastBarAddedAt = currentTime
            onMeteringUpdate?(level, currentTime)
        } else {
            onMeteringUpdate?(nil, currentTime)
        }
    }

    private func normalizedMeterLevel(power: Float) -> Float {
        let minDb: Float = -55
        let maxDb: Float = -5
        let clamped = min(max(power, minDb), maxDb)
        let linear = (clamped - minDb) / (maxDb - minDb)
        return max(0.08, powf(linear, 0.65))
    }
}
