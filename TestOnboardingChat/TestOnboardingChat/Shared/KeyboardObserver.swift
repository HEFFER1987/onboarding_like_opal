//
//  KeyboardObserver.swift
//  TestOnboardingChat
//

import Combine
import SwiftUI
import UIKit

protocol KeyboardReadable {
    var keyboardWillChangePublisher: AnyPublisher<Bool, Never> { get }
    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> { get }
}

extension KeyboardReadable {
    var keyboardWillChangePublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }

    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardDidShowNotification)
            .map { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return CGFloat(0)
                }
                return frame.height
            }
            .eraseToAnyPublisher()
    }
}

struct KeyboardHeightObserver: ViewModifier, KeyboardReadable {
    @Binding var keyboardHeight: CGFloat
    var onKeyboardShown: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onReceive(keyboardHeightPublisher) { height in
                if height > 0 {
                    keyboardHeight = height
                }
            }
            .onReceive(keyboardWillChangePublisher) { shown in
                if shown {
                    onKeyboardShown?()
                } else {
                    keyboardHeight = 0
                }
            }
    }
}

extension View {
    func observeKeyboardHeight(
        _ height: Binding<CGFloat>,
        onKeyboardShown: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardHeightObserver(keyboardHeight: height, onKeyboardShown: onKeyboardShown))
    }
}
