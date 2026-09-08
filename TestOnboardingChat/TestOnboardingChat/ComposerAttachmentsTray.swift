//
//  ComposerAttachmentsTray.swift
//  TestOnboardingChat
//

import SwiftUI

struct ComposerAttachmentsTray: View {
    var assets: [ComposerAsset]
    var voiceRecordings: [ComposerVoiceRecording]
    var playback: VoiceRecordingPlaybackService
    var location: ComposerLocation?
    var onRemove: (String) -> Void

    private var hasContent: Bool {
        !assets.isEmpty || !voiceRecordings.isEmpty || location != nil
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 8) {
                if !assets.isEmpty {
                    ComposerAttachmentsContainerView(
                        assets: assets,
                        onDiscardAttachment: onRemove
                    )
                    .transition(.scale)
                }

                if !voiceRecordings.isEmpty {
                    ComposerVoiceRecordingTrayView(
                        recordings: voiceRecordings,
                        playback: playback,
                        onRemove: onRemove
                    )
                    .transition(.scale)
                }

                if let location {
                    ComposerLocationAttachmentView(
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
