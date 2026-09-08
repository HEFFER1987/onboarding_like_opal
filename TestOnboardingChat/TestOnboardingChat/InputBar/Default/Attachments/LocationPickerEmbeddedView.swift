//
//  LocationPickerEmbeddedView.swift
//  TestOnboardingChat
//

import SwiftUI

struct LocationPickerEmbeddedView: View {
    @Bindable var viewModel: LocationPickerViewModel
    var isSheetPresented: Bool
    var onLocationSelected: (InputBarLocation) -> Void

    var body: some View {
        Group {
            if viewModel.locationService.isAccessDenied {
                permissionDeniedView
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        LocationPickerMapSection(
                            viewModel: viewModel,
                            showsSearchBar: false,
                            showsExpandButton: true,
                            showsCollapseButton: false,
                            onExpand: {
                                viewModel.expandSheet()
                            },
                            onCollapse: {}
                        )
                    }
                    .frame(height: viewModel.halfSheetMapHeight)

                    LocationVenueListView(
                        currentAddress: viewModel.addressLine,
                        isGeocoding: viewModel.isGeocoding,
                        venues: viewModel.venues,
                        isLoadingVenues: viewModel.isLoadingVenues,
                        onSelectCurrentLocation: {
                            guard let location = viewModel.sendSelectedLocation() else { return }
                            onLocationSelected(location)
                        },
                        onSelectVenue: { venue in
                            viewModel.selectVenue(venue)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            if !isSheetPresented {
                viewModel.onDisappear()
            }
        }
        .onChange(of: viewModel.locationService.currentLocation) { _, location in
            guard let location else { return }
            viewModel.handleInitialLocation(location)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.45))

            Text("Location access required")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Button("Open Settings") {
                viewModel.openSettings()
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(LocationPickerColors.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
