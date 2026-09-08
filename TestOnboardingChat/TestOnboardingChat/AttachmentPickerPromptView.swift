//
//  AttachmentPickerPromptView.swift
//  TestOnboardingChat
//

import SwiftUI

struct AttachmentPickerPromptView: View {
    let image: Image
    let description: String
    let buttonText: String
    let onTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        image
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(description)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 300)
                    }

                    Button(buttonText, action: onTap)
                        .buttonStyle(.bordered)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .frame(minHeight: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
