//
//  InputBarLocationAttachmentView.swift
//  TestOnboardingChat
//

import MapKit
import SwiftUI

struct InputBarLocationAttachmentView: View {
    let location: InputBarLocation
    let onDiscard: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            MapSnapshotView(coordinate: location.coordinate)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Label(location.label ?? "Location", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(coordinateText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .dismissButtonOverlay {
            onDiscard(location.id)
        }
    }

    private var coordinateText: String {
        String(format: "%.4f, %.4f", location.latitude, location.longitude)
    }
}
