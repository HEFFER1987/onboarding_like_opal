//
//  ChatInputBar.swift
//  TestOnboardingChat
//

import SwiftUI

protocol ChatInputBarController: AnyObject {
    func updateKeyboardHeight(_ height: CGFloat)
    func reset()
    var hasSubmittableAttachments: Bool { get }
    var isVoiceRecordingActive: Bool { get }
    func voiceSubmissionSummary() -> String?
    func clearSubmittedAttachments()
}

protocol ChatInputBarFactory {
    func makeController() -> ChatInputBarController
    func makeView(
        controller: ChatInputBarController,
        text: Binding<String>,
        placeholder: String,
        isSendEnabled: Bool,
        isInteractionEnabled: Bool,
        isFocused: Binding<Bool>,
        onSend: @escaping () -> Void
    ) -> AnyView
}
