//
//  AttachmentTypeTabs.swift
//  TestOnboardingChat
//

import SwiftUI

struct AttachmentTypeTabs: View {
    var tabs: [AttachmentPickerTab]
    var selected: AttachmentPickerTab
    var onSelect: (AttachmentPickerTab) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(tab: tab, icon: icon(for: tab), label: label(for: tab))
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
    }

    private func icon(for tab: AttachmentPickerTab) -> String {
        switch tab {
        case .photos:
            "photo"
        case .camera:
            "camera"
        case .files:
            "doc"
        case .location:
            "mappin.and.ellipse"
        }
    }

    private func label(for tab: AttachmentPickerTab) -> String {
        switch tab {
        case .photos:
            "Photos"
        case .camera:
            "Camera"
        case .files:
            "Files"
        case .location:
            "Location"
        }
    }

    private func tabButton(tab: AttachmentPickerTab, icon: String, label: String) -> some View {
        Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selected == tab ? .white : .white.opacity(0.5))
            .frame(width: 64, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected == tab ? Color.white.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
