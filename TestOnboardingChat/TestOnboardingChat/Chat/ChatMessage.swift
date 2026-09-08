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

    static let blurStepPercent: CGFloat = 2.5
    static let maxBlurPercent: CGFloat = 100
    static let maxBlurRadius: CGFloat = 20
    static let minTextOpacity: CGFloat = 0.6
    static let defaultFocusRatio: CGFloat = 0.72
    static let blurFalloffRatio: CGFloat = 0.55

    struct Appearance: Equatable {
        let blurRadius: CGFloat
        let textOpacity: CGFloat
    }

    static func blurZoneHeight(viewportHeight: CGFloat) -> CGFloat {
        guard viewportHeight > 0 else { return 0 }
        return viewportHeight * defaultFocusRatio
    }

    static func appearance(
        messageCenterY: CGFloat,
        viewportHeight: CGFloat
    ) -> Appearance {
        guard viewportHeight > 0 else {
            return Appearance(blurRadius: 0, textOpacity: 1)
        }

        let focusY = blurZoneHeight(viewportHeight: viewportHeight)
        let distanceAboveFocus = focusY - messageCenterY
        guard distanceAboveFocus > 0 else {
            return Appearance(blurRadius: 0, textOpacity: 1)
        }

        let normalizedDistance = min(
            1,
            distanceAboveFocus / (viewportHeight * blurFalloffRatio)
        )
        return appearance(normalizedDistance: normalizedDistance)
    }

    static func appearance(stepsAboveActiveQuestion: Int) -> Appearance {
        guard stepsAboveActiveQuestion > 0 else {
            return Appearance(blurRadius: 0, textOpacity: 1)
        }

        let blurPercent = min(
            CGFloat(stepsAboveActiveQuestion) * blurStepPercent,
            maxBlurPercent
        )
        return appearance(normalizedDistance: blurPercent / maxBlurPercent)
    }

    private static func appearance(normalizedDistance: CGFloat) -> Appearance {
        Appearance(
            blurRadius: normalizedDistance * maxBlurRadius,
            textOpacity: 1 - normalizedDistance * (1 - minTextOpacity)
        )
    }

    static func blurRadius(stepsAboveActiveQuestion: Int) -> CGFloat {
        appearance(stepsAboveActiveQuestion: stepsAboveActiveQuestion).blurRadius
    }

    static func blurRadius(
        messageCenterY: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat {
        appearance(
            messageCenterY: messageCenterY,
            viewportHeight: viewportHeight
        ).blurRadius
    }

    static func textColor(for message: ChatMessage, opacity: CGFloat) -> Color {
        switch message.role {
        case .user:
            userColor.opacity(opacity)
        case .bot:
            Color.white.opacity(opacity)
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
    let blurRadius: CGFloat
    let textOpacity: CGFloat
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
                    .foregroundStyle(ChatDepthStyle.textColor(for: message, opacity: textOpacity))
            }
        }
        .font(.system(size: 22, weight: .regular))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .compositingGroup()
        .blur(radius: blurRadius)
    }
}
