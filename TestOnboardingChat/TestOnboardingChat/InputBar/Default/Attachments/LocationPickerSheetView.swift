//
//  LocationPickerSheetView.swift
//  TestOnboardingChat
//

import SwiftUI

struct LocationPickerSheetView: View {
    @Bindable var viewModel: LocationPickerViewModel
    var onLocationSelected: (InputBarLocation) -> Void
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.locationService.isAccessDenied {
                permissionDeniedView
            } else {
                LocationPickerMapSection(
                    viewModel: viewModel,
                    showsSearchBar: true,
                    showsExpandButton: false,
                    showsCollapseButton: true,
                    onExpand: {},
                    onCollapse: {
                        dismissSheet()
                    }
                )

                LocationPickerBottomChrome(viewModel: viewModel) {
                    guard let location = viewModel.sendSelectedLocation() else { return }
                    onLocationSelected(location)
                    dismissSheet()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.black)
        .presentationCornerRadius(20)
        .onAppear {
            viewModel.syncSheetExpansion(isExpanded: true)
        }
        .onDisappear {
            viewModel.syncSheetExpansion(isExpanded: false)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.45))

            Text("Location Access Required")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Button("Open Settings") {
                viewModel.openSettings()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(LocationPickerColors.accent)

            Button("Close") {
                dismissSheet()
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(.white.opacity(0.55))
        }
    }

    private func dismissSheet() {
        viewModel.collapseSheet()
        dismiss()
        onDismiss()
    }
}
