//
//  InputBarFactory.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarFactory: ChatInputBarFactory {
    var config: InputBarFeatureConfig = InputBarFeatureConfig()

    func makeController() -> ChatInputBarController {
        InputBarViewModel(config: config)
    }

    func makeView(
        controller: ChatInputBarController,
        text: Binding<String>,
        placeholder: String,
        isSendEnabled: Bool,
        isInteractionEnabled: Bool,
        isFocused: Binding<Bool>,
        onSend: @escaping () -> Void
    ) -> AnyView {
        guard let viewModel = controller as? InputBarViewModel else {
            return AnyView(EmptyView())
        }

        return AnyView(
            InputBarContainer(
                text: text,
                viewModel: viewModel,
                placeholder: placeholder,
                isSendEnabled: isSendEnabled,
                isInteractionEnabled: isInteractionEnabled,
                onSend: onSend,
                isFocused: isFocused
            )
        )
    }
}
