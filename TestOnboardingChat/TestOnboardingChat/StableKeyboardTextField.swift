//
//  StableKeyboardTextField.swift
//  TestOnboardingChat
//

import SwiftUI
import UIKit

private final class EmojiCapableTextField: UITextField {
    private var prefersEmojiKeyboard = false

    override var textInputContextIdentifier: String? {
        prefersEmojiKeyboard ? "" : nil
    }

    override var textInputMode: UITextInputMode? {
        guard prefersEmojiKeyboard else { return super.textInputMode }
        return UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
    }

    func showEmojiKeyboard() {
        prefersEmojiKeyboard = true

        if !isFirstResponder {
            becomeFirstResponder()
        }

        reloadInputViews()

        DispatchQueue.main.async { [weak self] in
            self?.prefersEmojiKeyboard = false
        }
    }
}

struct StableKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    @Binding var isFocused: Bool
    var isEnabled: Bool
    var emojiKeyboardTrigger: Int = 0
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = true

        let textField = EmojiCapableTextField()
        textField.delegate = context.coordinator
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 17)
        textField.textColor = .white
        textField.tintColor = UIColor(red: 0.45, green: 0.85, blue: 0.65, alpha: 1)
        textField.keyboardType = keyboardType
        textField.keyboardAppearance = .dark
        textField.returnKeyType = .send
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged),
            for: .editingChanged
        )

        applyKeyboardSettings(on: textField)

        container.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 22),
        ])

        context.coordinator.textField = textField
        updatePlaceholder(on: textField)

        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let textField = context.coordinator.textField else { return }

        if textField.text != text {
            textField.text = text
        }

        updatePlaceholder(on: textField)
        textField.isEnabled = isEnabled
        applyKeyboardSettings(on: textField)

        if textField.keyboardType != keyboardType {
            textField.keyboardType = keyboardType
            if textField.isFirstResponder {
                textField.reloadInputViews()
            }
        }

        let shouldShowEmojiKeyboard = context.coordinator.lastEmojiKeyboardTrigger != emojiKeyboardTrigger
        if shouldShowEmojiKeyboard {
            context.coordinator.lastEmojiKeyboardTrigger = emojiKeyboardTrigger
            (textField as? EmojiCapableTextField)?.showEmojiKeyboard()
        } else {
            syncFocus(on: textField)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: 22)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func applyKeyboardSettings(on textField: UITextField) {
        let usesSystemPredictions = keyboardType == .default

        textField.autocorrectionType = usesSystemPredictions ? .yes : .no
        textField.spellCheckingType = usesSystemPredictions ? .yes : .no
        textField.smartInsertDeleteType = usesSystemPredictions ? .default : .no
    }

    private func updatePlaceholder(on textField: UITextField) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.35)]
        )
    }

    private func syncFocus(on textField: UITextField) {
        if isFocused, isEnabled, !textField.isFirstResponder {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        } else if !isFocused, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: StableKeyboardTextField
        weak var textField: UITextField?
        var lastEmojiKeyboardTrigger = 0

        init(parent: StableKeyboardTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            guard parent.isFocused else { return }

            DispatchQueue.main.async {
                guard self.parent.isFocused else { return }
                textField.becomeFirstResponder()
            }
        }
    }
}
