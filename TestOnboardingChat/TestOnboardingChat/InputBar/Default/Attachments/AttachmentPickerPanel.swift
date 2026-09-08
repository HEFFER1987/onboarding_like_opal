//
//  AttachmentPickerPanel.swift
//  TestOnboardingChat
//

import SwiftUI

struct AttachmentPickerPanel: View {
    @Bindable var viewModel: InputBarViewModel

    var height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.config.availableAttachmentTabs.isEmpty {
                AttachmentTypeTabs(
                    tabs: viewModel.config.availableAttachmentTabs,
                    selected: viewModel.selectedPickerTab,
                    onSelect: { viewModel.setPickerTab($0) }
                )
            }

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
            LocationPickerEmbeddedView(
                viewModel: viewModel.locationPickerViewModel,
                isSheetPresented: viewModel.isLocationSheetPresented,
                onLocationSelected: { viewModel.setLocation($0) }
            )
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
