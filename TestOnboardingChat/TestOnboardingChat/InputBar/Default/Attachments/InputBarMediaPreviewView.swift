//
//  InputBarMediaPreviewView.swift
//  TestOnboardingChat
//

import AVKit
import SwiftUI

struct InputBarMediaPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let assets: [AddedMediaAsset]
    @State private var selectedIndex: Int

    init(assets: [AddedMediaAsset], selectedIndex: Int) {
        self.assets = assets
        _selectedIndex = State(initialValue: selectedIndex)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                    previewContent(for: asset)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: assets.count > 1 ? .automatic : .never))
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Close")
                }

                if assets.count > 1 {
                    ToolbarItem(placement: .principal) {
                        Text("\(selectedIndex + 1) / \(assets.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
        }
    }

    @ViewBuilder
    private func previewContent(for asset: AddedMediaAsset) -> some View {
        switch asset.type {
        case .image:
            ZoomableImagePreview(image: asset.image)
        case .video:
            InputBarVideoPreviewPlayer(url: asset.url)
        }
    }
}

private struct ZoomableImagePreview: View {
    let image: UIImage

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        GeometryReader { reader in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: reader.size.width * scale,
                        height: reader.size.height * scale
                    )
                    .gesture(magnificationGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let updated = lastScale * value
                scale = min(max(updated, 1), 4)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    scale = 1
                    lastScale = 1
                }
            }
    }
}

private struct InputBarVideoPreviewPlayer: View {
    let url: URL

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            guard player == nil else {
                player?.play()
                return
            }
            let newPlayer = AVPlayer(url: url)
            player = newPlayer
            newPlayer.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
