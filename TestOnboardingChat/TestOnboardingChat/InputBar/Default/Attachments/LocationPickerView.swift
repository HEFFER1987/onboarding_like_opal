//
//  LocationPickerView.swift
//  TestOnboardingChat
//

import MapKit
import SwiftUI

struct LocationPickerView: View {
    @State private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var hasCenteredOnUser = false
    @State private var isMapReady = false

    var onLocationSelected: (InputBarLocation) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if isMapReady {
                    mapContent
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)

            if let error = locationService.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.8))
            }

            HStack(spacing: 12) {
                Button("My Location") {
                    locationService.requestCurrentLocation()
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button("Use This Location") {
                    guard let coordinate = selectedCoordinate else {
                        locationService.requestCurrentLocation()
                        return
                    }
                    onLocationSelected(InputBarLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        label: "Current location"
                    ))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.14, green: 0.52, blue: 0.98))
                .disabled(selectedCoordinate == nil)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .onAppear {
            locationService.requestCurrentLocation()
            DispatchQueue.main.async {
                isMapReady = true
            }
        }
        .onChange(of: locationService.currentLocation) { _, location in
            guard let location, !hasCenteredOnUser else { return }
            centerOnCoordinate(location.coordinate)
        }
    }

    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: .all) {
                if let selectedCoordinate {
                    Marker("Selected", coordinate: selectedCoordinate)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onTapGesture { screenPoint in
                guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                selectedCoordinate = coordinate
            }
        }
    }

    private func centerOnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        hasCenteredOnUser = true
        selectedCoordinate = coordinate
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
}
