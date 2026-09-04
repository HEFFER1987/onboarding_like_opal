//
//  OnboardingView.swift
//  TestOnboardingChat
//

import SwiftUI

private enum InputStep: Equatable {
    case name
    case followUp(Int)
    case none
}

private enum ConversationScrollTarget: Hashable {
    case message(UUID)
    case bottom
}

struct OnboardingView: View {
    @State private var messages: [ChatMessage] = []
    @State private var typingCompletions: [UUID: () -> Void] = [:]
    @State private var inputText = ""
    @State private var inputStep: InputStep = .none
    @State private var keyboardHeight: CGFloat = 0

    @FocusState private var isFieldFocused: Bool

    private let followUpQuestions = OnboardingQuestion.followUp
    private let chatAnimation = Animation.easeInOut(duration: 0.55)

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedInput.isEmpty
    }

    private var submitTitle: String {
        switch inputStep {
        case .followUp(let index) where index == followUpQuestions.count - 1:
            "Finish"
        default:
            "Continue"
        }
    }

    private var placeholder: String {
        switch inputStep {
        case .name:
            "John"
        case .followUp(let index):
            followUpQuestions[index].placeholder
        case .none:
            ""
        }
    }

    private var activeBotMessageID: UUID? {
        messages.last(where: { $0.role == .bot })?.id
    }

    private var activeBotMessageIndex: Int? {
        messages.lastIndex(where: { $0.role == .bot })
    }

    private func blurRadius(forMessageAt index: Int) -> CGFloat {
        guard let activeIndex = activeBotMessageIndex else { return 0 }
        let stepsAbove = max(0, activeIndex - index)
        return ChatDepthStyle.blurRadius(stepsAboveActiveQuestion: stepsAbove)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                conversationArea
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                inputSection
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .background(Color.black)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: resetConversation) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()
            }
        }
        .onAppear(perform: startConversation)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            let nextHeight = max(0, screenHeight - frame.minY)

            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = nextHeight
            }
        }
    }

    private var conversationArea: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            ChatMessageRow(
                                message: message,
                                isActiveQuestion: message.id == activeBotMessageID,
                                blurRadius: blurRadius(forMessageAt: index),
                                onTypingComplete: {
                                    completeBotTyping(messageID: message.id)
                                },
                                onTypingUpdate: {
                                    scrollToActiveContent(
                                        proxy: proxy,
                                        viewportHeight: geometry.size.height,
                                        viewportWidth: geometry.size.width,
                                        animated: false
                                    )
                                }
                            )
                            .chatMessageTransition()
                            .id(ConversationScrollTarget.message(message.id))
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(ConversationScrollTarget.bottom)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .bottom)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                }
                .scrollDisabled(true)
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: geometry.size.height) { _, _ in
                    guard isFieldFocused || keyboardHeight > 0 else { return }
                    scrollToActiveContent(
                        proxy: proxy,
                        viewportHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToActiveContent(
                        proxy: proxy,
                        viewportHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: isFieldFocused) { _, focused in
                    guard focused else { return }
                    scrollToActiveContent(
                        proxy: proxy,
                        viewportHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: keyboardHeight) { _, _ in
                    guard isFieldFocused || keyboardHeight > 0 else { return }
                    scrollToActiveContent(
                        proxy: proxy,
                        viewportHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: activeBotMessageID) { _, _ in
                    scrollToActiveContent(
                        proxy: proxy,
                        viewportHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var inputSection: some View {
        VStack(spacing: 20) {
            OpalTextField(
                text: $inputText,
                placeholder: placeholder,
                keyboardType: keyboardType,
                textAlignment: .leading
            )
            .focused($isFieldFocused)

            GradientContinueButton(
                title: submitTitle,
                isEnabled: canSubmit,
                action: submitAnswer
            )
        }
    }

    private var keyboardType: UIKeyboardType {
        guard case .followUp(let index) = inputStep else { return .default }
        switch followUpQuestions[index].id {
        case 1, 2: return .numberPad
        default: return .default
        }
    }

    private func scrollToActiveContent(
        proxy: ScrollViewProxy,
        viewportHeight: CGFloat,
        viewportWidth: CGFloat,
        animated: Bool = true
    ) {
        DispatchQueue.main.async {
            let scroll = {
                let targetMessage = activeBotMessage ?? messages.last
                let anchor: UnitPoint
                if let targetMessage {
                    anchor = scrollAnchor(
                        for: targetMessage.text,
                        viewportHeight: viewportHeight,
                        viewportWidth: viewportWidth,
                        isTyping: targetMessage.role == .bot && !targetMessage.isTypingComplete
                    )
                } else {
                    anchor = .bottom
                }

                if let targetMessage {
                    proxy.scrollTo(
                        ConversationScrollTarget.message(targetMessage.id),
                        anchor: anchor
                    )
                } else {
                    proxy.scrollTo(ConversationScrollTarget.bottom, anchor: .bottom)
                }
            }

            if animated {
                withAnimation(chatAnimation) { scroll() }
            } else {
                scroll()
            }
        }
    }

    private var activeBotMessage: ChatMessage? {
        guard let activeBotMessageID else { return nil }
        return messages.first(where: { $0.id == activeBotMessageID })
    }

    private func scrollAnchor(
        for text: String,
        viewportHeight: CGFloat,
        viewportWidth: CGFloat,
        isTyping: Bool
    ) -> UnitPoint {
        let estimatedLineHeight: CGFloat = 28
        let horizontalPadding: CGFloat = 64
        let contentWidth = max(1, viewportWidth - horizontalPadding)
        let charsPerLine = max(1, Int(contentWidth / 12))
        let lineCount = max(1, Int(ceil(Double(text.count) / Double(charsPerLine))))
        let estimatedHeight = CGFloat(lineCount) * estimatedLineHeight

        if isTyping && estimatedHeight > viewportHeight * 0.45 {
            return .top
        }
        return .bottom
    }

    private func startConversation() {
        guard messages.isEmpty else { return }

        startBotTyping("I'll help protect your focus.") {
            startBotTyping("First, what's your name?") {
                inputStep = .name
                inputText = ""
            }
        }
    }

    private func resetConversation() {
        isFieldFocused = false
        typingCompletions.removeAll()
        inputText = ""
        inputStep = .none
        messages.removeAll()
        startConversation()
    }

    private func startBotTyping(
        _ text: String,
        speed: Duration = .milliseconds(35),
        onComplete: @escaping () -> Void
    ) {
        let message = ChatMessage(
            role: .bot,
            text: text,
            isTypingComplete: false,
            typingSpeed: speed
        )
        typingCompletions[message.id] = onComplete

        withAnimation(chatAnimation) {
            messages.append(message)
        }
    }

    private func completeBotTyping(messageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }

        messages[index].isTypingComplete = true
        typingCompletions[messageID]?()
        typingCompletions.removeValue(forKey: messageID)
    }

    private func appendUserMessage(_ text: String) {
        messages.append(ChatMessage(role: .user, text: text))
    }

    private func submitAnswer() {
        guard canSubmit else { return }

        isFieldFocused = false

        switch inputStep {
        case .name:
            let name = trimmedInput
            withAnimation(chatAnimation) {
                appendUserMessage("Hi, \(name).")
            }
            inputText = ""

            startBotTyping(
                "I'm going to ask you a few questions. No need to overthink it. Then I'll build your setup"
            ) {
                askFollowUpQuestion(at: 0)
            }

        case .followUp(let index):
            withAnimation(chatAnimation) {
                appendUserMessage(trimmedInput)
            }
            inputText = ""

            let nextIndex = index + 1
            if nextIndex < followUpQuestions.count {
                askFollowUpQuestion(at: nextIndex)
            } else {
                inputStep = .none
                finishConversation(userName: messages.first(where: { $0.role == .user })?.text ?? trimmedInput)
            }

        case .none:
            break
        }
    }

    private func askFollowUpQuestion(at index: Int) {
        inputStep = .followUp(index)
        inputText = ""

        startBotTyping(followUpQuestions[index].text) {
            isFieldFocused = true
        }
    }

    private func finishConversation(userName: String) {
        let displayName = userName
            .replacingOccurrences(of: "Hi, ", with: "")
            .replacingOccurrences(of: ".", with: "")

        startBotTyping("You're all set, \(displayName)!") {
            startBotTyping("We'll help you stay focused.", speed: .milliseconds(25)) {
                isFieldFocused = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
