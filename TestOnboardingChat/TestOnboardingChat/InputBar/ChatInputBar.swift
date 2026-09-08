//
//  ChatInputBar.swift
//  TestOnboardingChat
//

import SwiftUI

protocol ChatInputBarController: AnyObject {
    func updateKeyboardHeight(_ height: CGFloat)
    func reset()
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
