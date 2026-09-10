//
//  InputBarView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    @Bindable var viewModel: InputBarViewModel
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSendEnabled: Bool
    var isInteractionEnabled: Bool = true
    var onSend: () -> Void
    @Binding var isFocused: Bool

    @State private var showsKeyboardButton = false
    @State private var keyboardModeTrigger = 0
    @State private var pendingEmojiKeyboard = false
    @State private var isKeyboardSwitching = false

    private let barHeight: CGFloat = 36
    private let inputAreaHeight: CGFloat = 48
    private let actionButtonSize: CGFloat = 36
    private let trailingActionOffset: CGFloat = 6
    private let actionFill = Color.white.opacity(0.85)

    private var showsRecordingControlRow: Bool {
        viewModel.recordingState.isLockedOrStopped
    }

    private var showsSend: Bool {
        !text.isEmpty || viewModel.hasPendingAttachments
    }

    private var showsMic: Bool {
        viewModel.config.isVoiceRecordingEnabled
            && text.isEmpty
            && !viewModel.hasPendingAttachments
            && viewModel.recordingState.showsTextInput
    }

    private var isPickerExpanded: Bool {
        viewModel.isPickerShown
    }

    private var showsVoiceRecordingOverlay: Bool {
        viewModel.shouldShowRecordingGestureOverlay
            && text.isEmpty
            && !viewModel.hasPendingAttachments
    }

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.recordingState.showsTextInput || viewModel.hasPendingAttachments {
                InputBarAttachmentsTray(
                    assets: viewModel.pendingAssets,
                    voiceRecordings: viewModel.pendingVoiceRecordings,
                    playback: viewModel.voicePlayback,
                    location: viewModel.pendingLocation,
                    onRemove: { viewModel.removeAttachment(id: $0) }
                )
            }

            HStack(alignment: .bottom, spacing: 8) {
                if viewModel.config.isAttachmentButtonVisible && viewModel.recordingState.showsTextInput {
                    attachButton
                }

                inputArea
                    .frame(maxWidth: .infinity)

                if !showsRecordingControlRow {
                    trailingActionSlot
                        .frame(width: actionButtonSize, height: actionButtonSize)
                        .offset(x: trailingActionOffset)
                }
            }
        }
        .overlay {
            ZStack {
                recordingOverlay
                if showsVoiceRecordingOverlay {
                    voiceRecordingGestureOverlay
                        .transaction { $0.animation = nil }
                }
            }
            .transaction { $0.animation = nil }
        }
        .animation(.easeInOut(duration: 0.2), value: showsSend)
    }

    // MARK: - Input Area

    private var showsTextInput: Bool {
        viewModel.recordingState.showsTextInput
    }

    private var inputArea: some View {
        ZStack(alignment: .leading) {
            inputCapsule
                .opacity(showsTextInput ? 1 : 0)
                .allowsHitTesting(showsTextInput)
                .accessibilityHidden(!showsTextInput)

            voiceRecordingInput
                .opacity(showsTextInput ? 0 : 1)
                .allowsHitTesting(!showsTextInput)
                .accessibilityHidden(showsTextInput)
        }
        .frame(minHeight: inputAreaHeight)
        .animation(nil, value: showsTextInput)
    }

    private var voiceRecordingInput: some View {
        VoiceRecordingInputView(
            recordingState: viewModel.recordingState,
            isRecordingPaused: viewModel.isRecordingPaused,
            audioRecordingInfo: viewModel.audioRecordingInfo,
            pendingAudioRecordingURL: viewModel.pendingAudioRecording?.url,
            gestureLocation: viewModel.recordingGestureLocation,
            playback: viewModel.voicePlayback,
            toggleRecordingPause: { viewModel.toggleRecordingPause() },
            confirmRecording: { viewModel.confirmRecording() },
            discardRecording: { viewModel.discardRecording() }
        )
    }

    private var inputCapsule: some View {
        HStack(spacing: 0) {
            StableKeyboardTextField(
                text: $text,
                placeholder: placeholder,
                keyboardType: keyboardType,
                isFocused: $isFocused,
                isEnabled: isInteractionEnabled,
                switchToEmojiKeyboard: pendingEmojiKeyboard,
                keyboardModeTrigger: keyboardModeTrigger,
                isKeyboardSwitching: $isKeyboardSwitching,
                onSubmit: {
                    guard isSendEnabled else { return }
                    onSend()
                }
            )
            .padding(.leading, 12)
            .padding(.trailing, 4)

            emojiButton
        }
        .frame(height: inputAreaHeight)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
    }

    private var emojiButton: some View {
        Button {
            guard isInteractionEnabled else { return }
            isFocused = true
            isKeyboardSwitching = true

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showsKeyboardButton.toggle()
            }

            pendingEmojiKeyboard = showsKeyboardButton
            keyboardModeTrigger += 1
        } label: {
            ZStack {
                Image(systemName: "face.smiling")
                    .font(.system(size: 22, weight: .regular))
                    .opacity(showsKeyboardButton ? 0 : 1)

                Image(systemName: "keyboard")
                    .font(.system(size: 20, weight: .regular))
                    .opacity(showsKeyboardButton ? 1 : 0)
            }
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 36, height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isInteractionEnabled)
        .accessibilityLabel(showsKeyboardButton ? "Keyboard" : "Emoji")
        .transaction { $0.animation = nil }
    }

    private var attachButton: some View {
        Button {
            guard isInteractionEnabled else { return }
            isFocused = false
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleAttachmentPicker()
            }
        } label: {
            Image(systemName: "paperclip")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(isInteractionEnabled ? .white : .white.opacity(0.35))
                .rotationEffect(.degrees(isPickerExpanded ? 45 : 0))
                .frame(width: actionButtonSize, height: actionButtonSize)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isInteractionEnabled)
        .accessibilityLabel("Attach")
    }

    private var trailingActionSlot: some View {
        ZStack {
            if showsMic {
                micButton
                    .transition(.opacity.combined(with: .scale))
            }

            if showsSend {
                sendButton
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var micButton: some View {
        Image(systemName: "mic")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(isInteractionEnabled ? .white : .white.opacity(0.35))
            .frame(width: actionButtonSize, height: actionButtonSize)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.12))
            )
            .accessibilityLabel("Record voice message")
    }

    private var voiceRecordingGestureOverlay: some View {
        VoiceRecordingGestureOverlay(
            recordingState: Binding(
                get: { viewModel.recordingState },
                set: { viewModel.recordingState = $0 }
            ),
            gestureLocation: Binding(
                get: { viewModel.recordingGestureLocation },
                set: { viewModel.recordingGestureLocation = $0 }
            ),
            onRecordingStarted: { viewModel.startRecording() },
            onGestureCompleted: { viewModel.stopRecording() },
            onRecordingReleased: {
                if viewModel.config.isVoiceRecordingAutoSendEnabled {
                    viewModel.sendRecording()
                } else {
                    viewModel.saveRecording()
                }
            },
            onRecordingCancelled: { viewModel.discardRecording() },
            onShortTapDetected: { viewModel.showRecordingTip() }
        )
    }

    private var sendButton: some View {
        Button {
            guard isSendEnabled else { return }
            onSend()
            isFocused = true
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSendEnabled ? .black : .black.opacity(0.35))
                .frame(width: actionButtonSize, height: actionButtonSize)
                .background(
                    Circle()
                        .fill(isSendEnabled ? actionFill : actionFill.opacity(0.35))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isSendEnabled)
        .accessibilityLabel("Send")
    }

    // MARK: - Recording Overlay

    @ViewBuilder
    private var recordingOverlay: some View {
        if viewModel.showsRecordingOverlay {
            HStack {
                Spacer()
                VoiceRecordingLockView(
                    dragLocation: viewModel.recordingGestureLocation,
                    isLocked: viewModel.recordingState.isLockedOrStopped
                )
                .offset(y: viewModel.recordingState.isLockedOrStopped ? -80 : lockViewOffset)
            }
            .padding(.trailing, 0)
            .transition(.opacity)
        }
    }

    private var lockViewOffset: CGFloat {
        let location = viewModel.recordingGestureLocation
        if location.y > 0 { return -70 }
        let progress = min(1, -location.y / -VoiceRecordingConstants.lockMaxDistance)
        return -70 + (-80 - -70) * progress
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var isFocused = false
        @State private var viewModel = InputBarViewModel(config: InputBarFeatureConfig())

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                InputBarView(
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

    return PreviewWrapper()
}
