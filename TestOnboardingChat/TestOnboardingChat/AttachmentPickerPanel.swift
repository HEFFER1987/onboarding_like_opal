//
//  AttachmentPickerPanel.swift
//  TestOnboardingChat
//

import SwiftUI

struct AttachmentPickerPanel: View {
    @Bindable var viewModel: ComposerViewModel

    var height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            AttachmentTypeTabs(
                selected: viewModel.selectedPickerTab,
                onSelect: { viewModel.setPickerTab($0) }
            )

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: height)
        .background(Color.black.opacity(0.95))
        .clipped()
        .onAppear {
            if viewModel.photoLibraryAssets == nil {
                viewModel.askForPhotosPermission()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedPickerTab {
        case .photos:
            photosTab
        case .camera:
            AttachmentCameraPickerView(viewModel: viewModel)
        case .files:
            AttachmentFilePickerView(viewModel: viewModel)
        case .location:
            LocationPickerView { location in
                viewModel.setLocation(location)
            }
        }
    }

    private var photosTab: some View {
        AttachmentMediaPickerView(
            maxAttachmentSize: viewModel.config.maxAttachmentSize,
            photoLibraryAssets: viewModel.photoLibraryAssets,
            onImageTap: { viewModel.imageTapped($0) },
            imageSelected: { viewModel.isAssetSelected(id: $0) },
            selectedAssetIds: viewModel.selectedPhotoAssetIds,
            isDisplayed: viewModel.isPickerShown && viewModel.selectedPickerTab == .photos,
            onRequestAccess: { viewModel.askForPhotosPermission() }
        )
    }
}
