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
    @State private var inputSectionHeight: CGFloat = 60

    @State private var isFieldFocused = false
    @State private var composerVM = ComposerViewModel()

    private let followUpQuestions = OnboardingQuestion.followUp
    private let chatAnimation = Animation.easeInOut(duration: 0.55)
    private let botTypingStartDelay: Duration = .milliseconds(650)
    private let userMessageSettleDuration: Duration = .milliseconds(550)

    @State private var pendingUserAnswerTask: Task<Void, Never>?

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isBotTyping: Bool {
        messages.contains { $0.role == .bot && !$0.isTypingComplete }
    }

    private var canSubmit: Bool {
        !trimmedInput.isEmpty && !isBotTyping && inputStep != .none
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                inputSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .background(Color.black)
                    .background {
                        GeometryReader { inputGeometry in
                            Color.clear
                                .preference(
                                    key: InputSectionHeightPreferenceKey.self,
                                    value: inputGeometry.size.height
                                )
                        }
                    }
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
        .onPreferenceChange(InputSectionHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            inputSectionHeight = height
        }
        .onAppear(perform: startConversation)
        .onChange(of: isFieldFocused) { _, isFocused in
            if !isFocused {
                keyboardHeight = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            if #available(iOS 26, *) { return }

            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            let nextHeight = max(0, screenHeight - frame.minY)

            // iOS 18 can emit a transient keyboard-dismiss frame while the field stays focused.
            // Keep keyboard height stable while the bot is typing so the layout doesn't jump.
            if nextHeight == 0 && (isFieldFocused || isBotTyping) {
                return
            }

            keyboardHeight = nextHeight
            composerVM.updateKeyboardHeight(nextHeight)
        }
    }

    private func dismissKeyboard() {
        isFieldFocused = false
        keyboardHeight = 0
    }

    private var conversationArea: some View {
        GeometryReader { geometry in
            let visibleHeight = visibleConversationHeight(geometry.size.height)

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 28) {
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
                                        measuredHeight: geometry.size.height,
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
                    .frame(maxWidth: .infinity, minHeight: visibleHeight, alignment: .bottom)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                }
                .frame(height: visibleHeight, alignment: .top)
                .scrollDisabled(true)
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: geometry.size.height) { _, newHeight in
                    guard isFieldFocused || keyboardHeight > 0 else { return }
                    scrollToActiveContent(
                        proxy: proxy,
                        measuredHeight: newHeight,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToActiveContent(
                        proxy: proxy,
                        measuredHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                .onChange(of: keyboardHeight) { _, _ in
                    if #available(iOS 26, *) { return }
                    guard isFieldFocused || keyboardHeight > 0 else { return }
                    scrollToActiveContent(
                        proxy: proxy,
                        measuredHeight: geometry.size.height,
                        viewportWidth: geometry.size.width
                    )
                }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var inputSection: some View {
        ComposerContainer(
            text: $inputText,
            viewModel: composerVM,
            placeholder: placeholder,
            isSendEnabled: canSubmit,
            isInteractionEnabled: inputStep != .none,
            onSend: submitAnswer,
            isFocused: $isFieldFocused
        )
    }

    private func scrollToActiveContent(
        proxy: ScrollViewProxy,
        measuredHeight: CGFloat,
        viewportWidth: CGFloat,
        animated: Bool = true
    ) {
        DispatchQueue.main.async {
            let viewportHeight = visibleConversationHeight(measuredHeight)

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

    private func visibleConversationHeight(_ measuredHeight: CGFloat) -> CGFloat {
        if #available(iOS 26, *) { return measuredHeight }
        guard keyboardHeight > 0, isFieldFocused || isBotTyping else { return measuredHeight }

        let screenHeight = UIScreen.main.bounds.height
        let topInset: CGFloat = 72
        let maxHeight = max(
            120,
            screenHeight - keyboardHeight - inputSectionHeight - topInset
        )
        return min(measuredHeight, maxHeight)
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
                isFieldFocused = true
            }
        }
    }

    private func resetConversation() {
        pendingUserAnswerTask?.cancel()
        pendingUserAnswerTask = nil
        isFieldFocused = false
        typingCompletions.removeAll()
        inputText = ""
        inputStep = .none
        composerVM.clearAll()
        messages.removeAll()
        startConversation()
    }

    private func startBotTyping(
        _ text: String,
        speed: Duration = .milliseconds(35),
        onComplete: @escaping () -> Void
    ) {
        let typingStartDelay: Duration = messages.contains(where: { $0.role == .bot })
            ? botTypingStartDelay
            : .zero

        let message = ChatMessage(
            role: .bot,
            text: text,
            isTypingComplete: false,
            typingSpeed: speed,
            typingStartDelay: typingStartDelay
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

    private func appendUserMessageThen(_ text: String, action: @escaping () -> Void) {
        pendingUserAnswerTask?.cancel()

        withAnimation(chatAnimation) {
            appendUserMessage(text)
        }
        inputText = ""
        isFieldFocused = true

        pendingUserAnswerTask = Task { @MainActor in
            try? await Task.sleep(for: userMessageSettleDuration)
            guard !Task.isCancelled else { return }
            action()
            pendingUserAnswerTask = nil
        }
    }

    private func submitAnswer() {
        guard canSubmit else { return }

        switch inputStep {
        case .name:
            let name = trimmedInput
            appendUserMessageThen("Hi, \(name).") {
                startBotTyping(
                    "I'm going to ask you a few questions. No need to overthink it. Then I'll build your setup"
                ) {
                    askFollowUpQuestion(at: 0)
                }
            }

        case .followUp(let index):
            appendUserMessageThen(trimmedInput) {
                let nextIndex = index + 1
                if nextIndex < followUpQuestions.count {
                    askFollowUpQuestion(at: nextIndex)
                } else {
                    inputStep = .none
                    finishConversation(userName: messages.first(where: { $0.role == .user })?.text ?? trimmedInput)
                }
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

private struct InputSectionHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    OnboardingView()
}
