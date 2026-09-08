//
//  LocationPickerMapSection.swift
//  TestOnboardingChat
//

import MapKit
import SwiftUI

struct LocationPickerMapSection: View {
    @Bindable var viewModel: LocationPickerViewModel
    var showsSearchBar: Bool
    var showsExpandButton: Bool
    var showsCollapseButton: Bool
    var onExpand: () -> Void
    var onCollapse: () -> Void

    private var searchResultsMaxHeight: CGFloat {
        viewModel.isSheetExpanded ? 320 : 140
    }

    var body: some View {
        ZStack {
            mapLayer
            LocationPickerPinView(isRaised: viewModel.pinRaised)
                .offset(y: -10)
            mapControlsOverlay
        }
    }

    private var mapLayer: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            if viewModel.locationService.isAuthorized {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
                .mapControlVisibility(.hidden)
        }
        .onMapCameraChange(frequency: .continuous) { context in
            guard !viewModel.shouldIgnoreCameraChange() else { return }
            viewModel.handleCameraDrag(to: context.region.center)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            if viewModel.shouldIgnoreCameraChange() {
                viewModel.handleProgrammaticCameraEnd(span: context.region.span)
                return
            }
            viewModel.handleCameraSettled(
                at: context.region.center,
                span: context.region.span
            )
        }
    }

    private var mapControlsOverlay: some View {
        MapTopControls(
            viewModel: viewModel,
            showsSearchBar: showsSearchBar,
            showsExpandButton: showsExpandButton,
            showsCollapseButton: showsCollapseButton,
            searchResultsMaxHeight: searchResultsMaxHeight,
            onExpand: onExpand,
            onCollapse: onCollapse
        )
    }
}

private struct MapTopControls: View {
    @Bindable var viewModel: LocationPickerViewModel
    var showsSearchBar: Bool
    var showsExpandButton: Bool
    var showsCollapseButton: Bool
    var searchResultsMaxHeight: CGFloat
    var onExpand: () -> Void
    var onCollapse: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if showsCollapseButton {
                    mapControlButton(systemName: "chevron.down", action: onCollapse)
                }

                if showsSearchBar {
                    LocationMapSearchBar(
                        viewModel: viewModel,
                        isSearchFocused: $isSearchFocused
                    )
                }

                Spacer(minLength: 0)

                if showsExpandButton {
                    mapControlButton(systemName: "arrow.up.left.and.arrow.down.right", action: onExpand)
                }

                mapControlButton(systemName: "location.fill") {
                    viewModel.goToUserLocation()
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)

            if showsSearchBar, viewModel.showsSearchResultsPanel {
                LocationMapSearchResultsPanel(
                    viewModel: viewModel,
                    resultsMaxHeight: searchResultsMaxHeight,
                    onSelectResult: {
                        isSearchFocused = false
                    }
                )
                .padding(.horizontal, 12)
            }

            Spacer()
        }
    }

    private func mapControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LocationPickerColors.accent)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct LocationPickerBottomChrome: View {
    @Bindable var viewModel: LocationPickerViewModel
    var onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                if let error = viewModel.locationService.errorMessage,
                   !viewModel.locationService.isAccessDenied {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                if viewModel.showSendButton, viewModel.selectedCoordinate != nil {
                    Button(action: onSend) {
                        VStack(spacing: 2) {
                            Text("Send Location")
                                .font(.system(size: 17, weight: .semibold))
                            Text(viewModel.addressLine)
                                .font(.system(size: 13, weight: .medium))
                                .opacity(0.72)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LocationPickerColors.buttonBackground, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: LocationPickerColors.buttonShadow, radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .transition(
                        .scale(scale: 0.92, anchor: .bottom)
                            .combined(with: .opacity)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}
