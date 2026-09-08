//
//  InputBarAttachmentsTray.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarAttachmentsTray: View {
    var assets: [InputBarAsset]
    var voiceRecordings: [InputBarVoiceRecording]
    var playback: VoiceRecordingPlaybackService
    var location: InputBarLocation?
    var onRemove: (String) -> Void

    private var hasContent: Bool {
        !assets.isEmpty || !voiceRecordings.isEmpty || location != nil
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 8) {
                if !assets.isEmpty {
                    InputBarAttachmentsContainerView(
                        assets: assets,
                        onDiscardAttachment: onRemove
                    )
                    .transition(.scale)
                }

                if !voiceRecordings.isEmpty {
                    InputBarVoiceRecordingTrayView(
                        recordings: voiceRecordings,
                        playback: playback,
                        onRemove: onRemove
                    )
                    .transition(.scale)
                }

                if let location {
                    InputBarLocationAttachmentView(
                        location: location,
                        onDiscard: onRemove
                    )
                    .transition(.scale)
                }
            }
            .animation(.default, value: hasContent)
        }
    }
}
