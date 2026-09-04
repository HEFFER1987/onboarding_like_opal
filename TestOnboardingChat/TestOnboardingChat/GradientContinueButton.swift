//
//  GradientContinueButton.swift
//  TestOnboardingChat
//

import SwiftUI

struct GradientContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(alignment: .bottom) {
                    if isEnabled {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.85, blue: 0.2),
                                        Color(red: 0.4, green: 0.85, blue: 0.5),
                                        Color(red: 0.3, green: 0.7, blue: 0.95),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                            .mask(
                                VStack(spacing: 0) {
                                    Spacer()
                                    Rectangle().frame(height: 3)
                                }
                            )
                    }
                }
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            GradientContinueButton(title: "Continue", isEnabled: false, action: {})
            GradientContinueButton(title: "Continue", isEnabled: true, action: {})
        }
    }
}
