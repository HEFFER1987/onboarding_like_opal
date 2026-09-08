//
//  VoiceRecordingState.swift
//  TestOnboardingChat
//

import Foundation

enum VoiceRecordingState: Equatable, Sendable {
    case initial
    case recording
    case locked
    case stopped
}

extension VoiceRecordingState {
    var showsTextInput: Bool {
        self == .initial
    }

    var isRecording: Bool {
        self == .recording
    }

    var isLockedOrStopped: Bool {
        self == .locked || self == .stopped
    }
}
