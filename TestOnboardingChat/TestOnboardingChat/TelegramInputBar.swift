//
//  TelegramInputBar.swift
//  TestOnboardingChat
//

import SwiftUI

struct TelegramInputBar: View {
    @Binding var text: String
    @Bindable var viewModel: ComposerViewModel
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSendEnabled: Bool
    var isInteractionEnabled: Bool = true
    var onSend: () -> Void
    @Binding var isFocused: Bool

    @State private var emojiKeyboardTrigger = 0

    private let barHeight: CGFloat = 36
    private let actionButtonSize: CGFloat = 36
    private let sendBlue = Color(red: 0.14, green: 0.52, blue: 0.98)

    private var showsSend: Bool {
        !text.isEmpty || viewModel.hasPendingAttachments
    }

    private var showsMic: Bool {
        viewModel.config.isVoiceRecordingEnabled
            && text.isEmpty
            && !viewModel.hasPendingAttachments
            && viewModel.recordingState.showsComposer
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
            if viewModel.recordingState.showsComposer {
                ComposerAttachmentsTray(
                    assets: viewModel.pendingAssets,
                    voiceRecordings: viewModel.pendingVoiceRecordings,
                    playback: viewModel.voicePlayback,
                    location: viewModel.pendingLocation,
                    onRemove: { viewModel.removeAttachment(id: $0) }
                )
            }

            HStack(alignment: .bottom, spacing: 8) {
                attachButton

                inputArea
                    .frame(maxWidth: .infinity)

                trailingActionSlot
                    .frame(width: actionButtonSize, height: actionButtonSize)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.recordingState.showsComposer)
    }

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        if viewModel.recordingState.showsComposer {
            inputCapsule
        } else {
            VoiceRecordingInputView(
                recordingState: viewModel.recordingState,
                audioRecordingInfo: viewModel.audioRecordingInfo,
                pendingAudioRecordingURL: viewModel.pendingAudioRecording?.url,
                gestureLocation: viewModel.recordingGestureLocation,
                stopRecording: { viewModel.stopRecording() },
                confirmRecording: { viewModel.confirmRecording() },
                discardRecording: { viewModel.discardRecording() },
                previewRecording: { viewModel.previewRecording() }
            )
        }
    }

    private var inputCapsule: some View {
        HStack(spacing: 0) {
            StableKeyboardTextField(
                text: $text,
                placeholder: placeholder,
                keyboardType: keyboardType,
                isFocused: $isFocused,
                isEnabled: isInteractionEnabled,
                emojiKeyboardTrigger: emojiKeyboardTrigger,
                onSubmit: {
                    guard isSendEnabled else { return }
                    onSend()
                }
            )
            .padding(.leading, 12)
            .padding(.trailing, 4)

            emojiButton
        }
        .frame(minHeight: barHeight)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
    }

    private var emojiButton: some View {
        Button {
            guard isInteractionEnabled else { return }
            isFocused = true
            emojiKeyboardTrigger += 1
        } label: {
            Image(systemName: "face.smiling")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 36, height: barHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isInteractionEnabled)
        .accessibilityLabel("Emoji")
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
                .foregroundStyle(.white)
                .frame(width: actionButtonSize, height: actionButtonSize)
                .background(
                    Circle()
                        .fill(isSendEnabled ? sendBlue : sendBlue.opacity(0.35))
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
            .padding(.trailing, 16)
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
        @State private var viewModel = ComposerViewModel()

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                TelegramInputBar(
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
