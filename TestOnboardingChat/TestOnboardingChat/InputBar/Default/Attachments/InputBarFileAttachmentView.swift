//
//  InputBarFileAttachmentView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarFileAttachmentView: View {
    let url: URL
    let onDiscard: (String) -> Void
    var onOpen: () -> Void = {}

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 10) {
                fileIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    Text(url.composerFileSizeString)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 260)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .id(url.absoluteString)
        .accessibilityLabel("Open file")
        .dismissButtonOverlay {
            onDiscard(url.absoluteString)
        }
    }

    private var fileIcon: some View {
        Image(systemName: fileIconName)
            .font(.system(size: 22))
            .foregroundStyle(.white.opacity(0.75))
            .frame(width: 32, height: 40)
    }

    private var fileIconName: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return "doc.richtext"
        case "zip", "rar", "7z":
            return "doc.zipper"
        case "mp3", "wav", "m4a", "aac":
            return "waveform"
        case "txt", "md":
            return "doc.text"
        case "xls", "xlsx", "csv":
            return "tablecells"
        case "doc", "docx":
            return "doc"
        default:
            return "doc.fill"
        }
    }
}

private extension URL {
    var composerFileSizeString: String {
        _ = startAccessingSecurityScopedResource()
        defer { stopAccessingSecurityScopedResource() }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
