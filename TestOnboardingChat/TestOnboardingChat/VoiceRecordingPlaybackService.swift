//
//  VoiceRecordingPlaybackService.swift
//  TestOnboardingChat
//

import AVFoundation
import Observation

@Observable
@MainActor
final class VoiceRecordingPlaybackService {
    private(set) var playingURL: URL?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var playbackRate: Float = 1.0

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    func togglePlayback(for url: URL) {
        if playingURL == url, isPlaying {
            pause()
            return
        }
        if playingURL == url {
            resume()
            return
        }
        play(url: url)
    }

    func play(url: URL) {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.enableRate = true
            audioPlayer.rate = playbackRate
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
            playingURL = url
            isPlaying = true
            currentTime = 0
            startProgressTimer()
        } catch {
            stop()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
    }

    func resume() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        progressTimer?.invalidate()
        progressTimer = nil
        player?.stop()
        player = nil
        playingURL = nil
        isPlaying = false
        currentTime = 0
    }

    func cyclePlaybackRate() {
        switch playbackRate {
        case 1.0:
            playbackRate = 1.5
        case 1.5:
            playbackRate = 2.0
        default:
            playbackRate = 1.0
        }
        player?.rate = playbackRate
        if isPlaying {
            player?.play()
        }
    }

    func displayedTime(for url: URL, duration: TimeInterval) -> TimeInterval {
        guard playingURL == url else { return duration }
        return isPlaying ? currentTime : duration
    }

    func isActive(url: URL) -> Bool {
        playingURL == url
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let player = self.player else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.stop()
                }
            }
        }
    }
}
