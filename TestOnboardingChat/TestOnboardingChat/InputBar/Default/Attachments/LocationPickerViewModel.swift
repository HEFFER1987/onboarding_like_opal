//
//  LocationPickerViewModel.swift
//  TestOnboardingChat
//

import CoreLocation
import MapKit
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class LocationPickerViewModel {
    let locationService = LocationService()
    private let geocoder = LocationGeocoder()
    private let venueSearch = LocationVenueSearchService()
    private let searchService = LocationSearchService()

    var cameraPosition: MapCameraPosition = .automatic
    var selectedCoordinate: CLLocationCoordinate2D?
    var resolvedAddress: String?
    var isGeocoding = false
    var pinRaised = false
    var isPickingMode = false
    var showSendButton = false
    var isSheetExpanded = false
    var venues: [LocationVenue] = []
    var isLoadingVenues = false
    var hasInitialCentered = false
    var searchQuery = ""
    var searchResults: [LocationSearchResult] = []
    var isSearchingLocations = false
    var isSearchActive = false
    var isSearchFieldFocused = false

    var onRequestSheetExpansion: (() -> Void)?
    var onRequestSheetCollapse: (() -> Void)?

    private var pinDropTask: Task<Void, Never>?
    private var searchDebounceTask: Task<Void, Never>?
    private var searchAnchorCoordinate: CLLocationCoordinate2D?
    private var searchRequestID = 0
    private var isProgrammaticCameraMove = false
    private var currentMapSpan = LocationMapZoomLevel.street.span

    var showsSearchResultsPanel: Bool {
        isSearchActive && (!searchQuery.isEmpty || isSearchingLocations || !searchResults.isEmpty)
    }

    let halfSheetMapHeight: CGFloat = 200

    var addressLine: String {
        if isGeocoding {
            return "Locating…"
        }
        return resolvedAddress ?? "Unknown location"
    }

    func onAppear() {
        locationService.start()
    }

    func onDisappear() {
        pinDropTask?.cancel()
        searchDebounceTask?.cancel()
        geocoder.cancel()
        venueSearch.cancel()
        searchService.cancel()
        locationService.stop()
    }

    func handleInitialLocation(_ location: CLLocation) {
        guard !hasInitialCentered else { return }
        centerOnCoordinate(location.coordinate, fromUserLocation: true)
        hasInitialCentered = true
    }

    func handleCameraDrag(to coordinate: CLLocationCoordinate2D) {
        if !isPickingMode {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isPickingMode = true
            }
        }

        if !isSheetExpanded {
            isSheetExpanded = true
            onRequestSheetExpansion?()
        }

        if !pinRaised {
            pinDropTask?.cancel()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                pinRaised = true
            }
        }

        selectedCoordinate = coordinate
    }

    func handleCameraSettled(at coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        currentMapSpan = span
        selectedCoordinate = coordinate
        schedulePinDrop(wasDragging: true)
        reverseGeocode(coordinate)
        searchVenues(near: coordinate)

        if !showSendButton {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                showSendButton = true
            }
        }
    }

    func handleProgrammaticCameraEnd(span: MKCoordinateSpan) {
        currentMapSpan = span
        isProgrammaticCameraMove = false
    }

    func shouldIgnoreCameraChange() -> Bool {
        isProgrammaticCameraMove
    }

    func markProgrammaticCameraMove() {
        isProgrammaticCameraMove = true
    }

    func expandSheet() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            isPickingMode = true
            isSheetExpanded = true
        }
        onRequestSheetExpansion?()
    }

    func collapseSheet() {
        dismissSearch()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            isSheetExpanded = false
        }
        onRequestSheetCollapse?()
    }

    func syncSheetExpansion(isExpanded: Bool) {
        isSheetExpanded = isExpanded
    }

    func goToUserLocation() {
        if let location = locationService.currentLocation {
            hasInitialCentered = true
            centerOnCoordinate(location.coordinate, fromUserLocation: true)
            schedulePinDrop(wasDragging: false)
        } else {
            locationService.requestCurrentLocation()
        }
    }

    func selectVenue(_ venue: LocationVenue) {
        resolvedAddress = venue.subtitle.map { "\(venue.name), \($0)" } ?? venue.name
        centerOnCoordinate(venue.coordinate, zoomLevel: .street, fromUserLocation: false)
        schedulePinDrop(wasDragging: false)
        searchVenues(near: venue.coordinate)
    }

    func sendSelectedLocation() -> InputBarLocation? {
        guard let coordinate = selectedCoordinate else { return nil }
        return InputBarLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            label: resolvedAddress ?? "Location"
        )
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func handleSearchFocusChanged(_ isFocused: Bool) {
        isSearchFieldFocused = isFocused

        if isFocused {
            activateSearch()
        }
    }

    func activateSearch() {
        isSearchActive = true
        searchAnchorCoordinate = selectedCoordinate
            ?? locationService.currentLocation?.coordinate

        if !isSheetExpanded {
            expandSheet()
        }
    }

    func dismissSearch() {
        clearSearch()
        isSearchActive = false
        isSearchFieldFocused = false
        searchAnchorCoordinate = nil
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchDebounceTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearchingLocations = false
            searchService.cancel()
            return
        }

        if !isSearchActive {
            activateSearch()
        }

        isSearchingLocations = true
        searchDebounceTask = Task {
            try? await Task.sleep(for: .seconds(0.35))
            guard !Task.isCancelled else { return }
            performSearch(query: trimmed)
        }
    }

    func submitSearchQuery() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        searchDebounceTask?.cancel()
        isSearchingLocations = true
        performSearch(query: trimmed)
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearchingLocations = false
        searchDebounceTask?.cancel()
        searchService.cancel()
    }

    func selectSearchResult(_ result: LocationSearchResult) {
        switch result.kind {
        case .venue:
            resolvedAddress = result.subtitle.map { "\(result.title), \($0)" } ?? result.title
        case .address:
            resolvedAddress = result.subtitle.map { "\(result.title), \($0)" } ?? result.title
        }

        goToSearchCoordinate(result.coordinate, zoomLevel: result.zoomLevel)
        dismissSearch()
    }

    private func performSearch(query: String) {
        guard let anchor = currentSearchCoordinate else {
            isSearchingLocations = false
            return
        }

        searchRequestID += 1
        let requestID = searchRequestID

        searchService.search(
            query: query,
            near: anchor,
            referenceLocation: locationService.currentLocation
        ) { [weak self] results in
            guard let self else { return }
            guard requestID == searchRequestID else { return }
            searchResults = results
            isSearchingLocations = false
        }
    }

    private var currentSearchCoordinate: CLLocationCoordinate2D? {
        selectedCoordinate
            ?? searchAnchorCoordinate
            ?? locationService.currentLocation?.coordinate
    }

    private func goToSearchCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        zoomLevel: LocationMapZoomLevel
    ) {
        centerOnCoordinate(coordinate, zoomLevel: zoomLevel, fromUserLocation: false)
        schedulePinDrop(wasDragging: false)
    }

    private func schedulePinDrop(wasDragging: Bool) {
        pinDropTask?.cancel()
        pinDropTask = Task {
            let delay = wasDragging ? 0.38 : 0.05
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                pinRaised = false
            }
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        geocoder.reverseGeocode(coordinate: coordinate) { [weak self] address in
            guard let self else { return }
            resolvedAddress = address
            isGeocoding = false
        }
    }

    private func searchVenues(near coordinate: CLLocationCoordinate2D) {
        isLoadingVenues = true
        venueSearch.search(near: coordinate, referenceLocation: locationService.currentLocation) { [weak self] venues in
            guard let self else { return }
            self.venues = venues
            self.isLoadingVenues = false
        }
    }

    private func centerOnCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        zoomLevel: LocationMapZoomLevel = .street,
        fromUserLocation: Bool = false
    ) {
        let span = LocationMapZoomLevel.resolvedSpan(
            preferred: zoomLevel,
            fallback: currentMapSpan
        )
        currentMapSpan = span
        isProgrammaticCameraMove = true
        selectedCoordinate = coordinate

        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: span))
        }

        reverseGeocode(coordinate)
        searchVenues(near: coordinate)

        if fromUserLocation {
            pinRaised = false
        }

        if !showSendButton {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                showSendButton = true
            }
        }

        if !isPickingMode {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                isPickingMode = true
            }
        }
    }
}
