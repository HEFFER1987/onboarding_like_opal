//
//  OpalTextField.swift
//  TestOnboardingChat
//

import SwiftUI

struct OpalTextField: View {
    @Binding var text: String
    var placeholder: String = "John"
    var keyboardType: UIKeyboardType = .default
    var textAlignment: TextAlignment = .leading

    var body: some View {
        HStack {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.white.opacity(0.35)))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.white)
                .multilineTextAlignment(textAlignment)
                .keyboardType(keyboardType)
                .tint(Color(red: 0.45, green: 0.85, blue: 0.65))

            if textAlignment == .leading {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading:
            .leading
        case .trailing:
            .trailing
        case .center:
            .center
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OpalTextField(text: .constant(""))
    }
}
