//
//  ComposerContainer.swift
//  TestOnboardingChat
//

import SwiftUI

struct ComposerContainer: View {
    @Binding var text: String
    @Bindable var viewModel: ComposerViewModel
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSendEnabled: Bool
    var isInteractionEnabled: Bool = true
    var onSend: () -> Void
    @Binding var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TelegramInputBar(
                text: $text,
                viewModel: viewModel,
                placeholder: placeholder,
                keyboardType: keyboardType,
                isSendEnabled: isSendEnabled,
                isInteractionEnabled: isInteractionEnabled,
                onSend: onSend,
                isFocused: $isFocused
            )

            AttachmentPickerPanel(
                viewModel: viewModel,
                height: viewModel.isPickerShown ? viewModel.popupHeight : 0
            )
            .offset(y: viewModel.isPickerShown ? 0 : viewModel.popupHeight)
            .opacity(viewModel.isPickerShown ? 1 : 0)
            .clipped()
            .animation(.easeInOut(duration: 0.25), value: viewModel.isPickerShown)
        }
        .observeKeyboardHeight(
            Binding(
                get: { viewModel.keyboardHeight },
                set: { viewModel.updateKeyboardHeight($0) }
            ),
            onKeyboardShown: {
                viewModel.hidePicker()
            }
        )
        .alert("File too large", isPresented: Binding(
            get: { viewModel.attachmentSizeExceeded },
            set: { viewModel.attachmentSizeExceeded = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The selected file exceeds the maximum attachment size.")
        }
        .alert(
            "Voice Message",
            isPresented: Binding(
                get: { viewModel.recordingSnackBarText != nil },
                set: { if !$0 { viewModel.recordingSnackBarText = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.recordingSnackBarText = nil
            }
        } message: {
            Text(viewModel.recordingSnackBarText ?? "")
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var isFocused = false
        @State private var viewModel = ComposerViewModel()

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Spacer()
                    ComposerContainer(
                        text: $text,
                        viewModel: viewModel,
                        placeholder: "Message",
                        isSendEnabled: !text.isEmpty,
                        isInteractionEnabled: true,
                        onSend: {},
                        isFocused: $isFocused
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    return PreviewWrapper()
}
