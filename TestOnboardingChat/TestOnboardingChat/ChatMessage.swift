//
//  ChatMessage.swift
//  TestOnboardingChat
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let text: String
    var isTypingComplete: Bool
    var typingSpeed: Duration
    var typingStartDelay: Duration

    enum Role: Equatable {
        case bot
        case user
    }

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        isTypingComplete: Bool = true,
        typingSpeed: Duration = .milliseconds(35),
        typingStartDelay: Duration = .zero
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.isTypingComplete = isTypingComplete
        self.typingSpeed = typingSpeed
        self.typingStartDelay = typingStartDelay
    }
}

enum ChatDepthStyle {
    static let userColor = Color(red: 0.45, green: 0.82, blue: 0.72)
    static let botActiveColor = Color.white
    static let botInactiveColor = Color.white.opacity(0.6)

    static let blurStepPercent: CGFloat = 2.5
    static let maxBlurPercent: CGFloat = 100
    static let maxBlurRadius: CGFloat = 20

    static func blurRadius(stepsAboveActiveQuestion: Int) -> CGFloat {
        guard stepsAboveActiveQuestion > 0 else { return 0 }

        let blurPercent = min(
            CGFloat(stepsAboveActiveQuestion) * blurStepPercent,
            maxBlurPercent
        )
        return blurPercent / maxBlurPercent * maxBlurRadius
    }

    static func textColor(for message: ChatMessage, isActiveQuestion: Bool) -> Color {
        switch message.role {
        case .user:
            userColor
        case .bot:
            isActiveQuestion ? botActiveColor : botInactiveColor
        }
    }
}

extension View {
    func chatMessageTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .opacity
                    .combined(with: .offset(y: 14))
                    .combined(with: .scale(scale: 0.98, anchor: .bottomLeading)),
                removal: .opacity
            )
        )
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    let isActiveQuestion: Bool
    let blurRadius: CGFloat
    var onTypingComplete: (() -> Void)?
    var onTypingUpdate: (() -> Void)?

    var body: some View {
        Group {
            if message.role == .bot && !message.isTypingComplete {
                TypewriterText(
                    fullText: message.text,
                    speed: message.typingSpeed,
                    startDelay: message.typingStartDelay,
                    color: ChatDepthStyle.botActiveColor,
                    onComplete: onTypingComplete,
                    onUpdate: onTypingUpdate
                )
            } else {
                Text(message.text)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(ChatDepthStyle.textColor(for: message, isActiveQuestion: isActiveQuestion))
            }
        }
        .font(.system(size: 22, weight: .regular))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .compositingGroup()
        .blur(radius: blurRadius)
        .animation(.easeInOut(duration: 0.45), value: isActiveQuestion)
        .animation(.easeInOut(duration: 0.45), value: blurRadius)
    }
}
