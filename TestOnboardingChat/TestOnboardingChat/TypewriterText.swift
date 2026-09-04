//
//  TypewriterText.swift
//  TestOnboardingChat
//

import SwiftUI

struct TypewriterText: View {
    let fullText: String
    var speed: Duration = .milliseconds(35)
    var color: Color = .white
    var onComplete: (() -> Void)? = nil
    var onUpdate: (() -> Void)? = nil

    @State private var displayedText = ""
    @State private var isComplete = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        Text(displayedText)
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear { startTyping() }
            .onDisappear {
                task?.cancel()
                task = nil
            }
    }

    private func startTyping() {
        displayedText = ""
        isComplete = false
        task?.cancel()

        task = Task {
            for character in fullText {
                try? await Task.sleep(for: speed)
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                onUpdate?()
            }
            guard !Task.isCancelled else { return }
            isComplete = true
            onComplete?()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TypewriterText(fullText: "I'll help protect your focus.")
            .padding(.horizontal, 32)
    }
}
