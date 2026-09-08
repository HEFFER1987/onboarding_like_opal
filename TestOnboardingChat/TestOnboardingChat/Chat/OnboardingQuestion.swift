//
//  OnboardingQuestion.swift
//  TestOnboardingChat
//

import Foundation

struct OnboardingQuestion: Identifiable {
    let id: Int
    let text: String
    let placeholder: String
}

extension OnboardingQuestion {
    static let followUp: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: 1,
            text: "How old are you?",
            placeholder: "25"
        ),
        OnboardingQuestion(
            id: 2,
            text: "How many hours a day do you use your phone?",
            placeholder: "4"
        ),
        OnboardingQuestion(
            id: 3,
            text: "What distracts you the most?",
            placeholder: "Social media"
        ),
        OnboardingQuestion(
            id: 4,
            text: "What's your main goal?",
            placeholder: "Stay focused"
        ),
    ]
}
