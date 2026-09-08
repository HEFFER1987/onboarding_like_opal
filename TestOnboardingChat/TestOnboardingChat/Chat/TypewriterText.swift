//
//  TypewriterText.swift
//  TestOnboardingChat
//

import SwiftUI
import UIKit

private enum TypewriterHaptics {
    private static let generator = UIImpactFeedbackGenerator(style: .light)
    private static let minimumInterval: TimeInterval = 0.05
    private static var lastTickTime: TimeInterval = 0

    static func prepare() {
        lastTickTime = 0
        generator.prepare()
    }

    static func tickIfNeeded() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTickTime >= minimumInterval else { return }

        lastTickTime = now
        generator.impactOccurred(intensity: 0.65)
        generator.prepare()
    }
}

struct TypewriterText: View {
    let fullText: String
    var speed: Duration = .milliseconds(35)
    var startDelay: Duration = .zero
    var color: Color = .white
    var onComplete: (() -> Void)? = nil
    var onUpdate: (() -> Void)? = nil

    @State private var displayedText = ""
    @State private var isComplete = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(fullText)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(color)
                .opacity(0)
                .accessibilityHidden(true)

            Text(displayedText)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(color)
        }
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
        TypewriterHaptics.prepare()

        task = Task {
            if startDelay > .zero {
                try? await Task.sleep(for: startDelay)
                guard !Task.isCancelled else { return }
            }

            for character in fullText {
                try? await Task.sleep(for: speed)
                guard !Task.isCancelled else { return }
                displayedText.append(character)
                TypewriterHaptics.tickIfNeeded()
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
