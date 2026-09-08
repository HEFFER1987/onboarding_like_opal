//
//  AttachmentTypeTabs.swift
//  TestOnboardingChat
//

import SwiftUI

struct AttachmentTypeTabs: View {
    var selected: AttachmentPickerTab
    var onSelect: (AttachmentPickerTab) -> Void

    var body: some View {
        HStack(spacing: 4) {
            tabButton(tab: .photos, icon: "photo", label: "Photos")
            tabButton(tab: .camera, icon: "camera", label: "Camera")
            tabButton(tab: .files, icon: "doc", label: "Files")
            tabButton(tab: .location, icon: "mappin.and.ellipse", label: "Location")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
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
