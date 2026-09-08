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

    var onLocationSelected: (ComposerLocation) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Map(position: $cameraPosition, interactionModes: .all) {
                if let selectedCoordinate {
                    Marker("Selected", coordinate: selectedCoordinate)
                }
                if let current = locationService.currentLocation?.coordinate, selectedCoordinate == nil {
                    Marker("You", coordinate: current)
                }
            }
            .onTapGesture { }
            .mapStyle(.standard(elevation: .flat))
            .frame(maxHeight: .infinity)

            if let error = locationService.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.8))
            }

            HStack(spacing: 12) {
                Button("My Location") {
                    locationService.requestCurrentLocation()
                    if let coordinate = locationService.currentLocation?.coordinate {
                        selectedCoordinate = coordinate
                        cameraPosition = .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button("Use This Location") {
                    guard let coordinate = selectedCoordinate ?? locationService.currentLocation?.coordinate else {
                        locationService.requestCurrentLocation()
                        return
                    }
                    onLocationSelected(ComposerLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        label: "Current location"
                    ))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.14, green: 0.52, blue: 0.98))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .onAppear {
            locationService.requestCurrentLocation()
        }
        .onChange(of: locationService.currentLocation) { _, location in
            guard let location, selectedCoordinate == nil else { return }
            let coordinate = location.coordinate
            selectedCoordinate = coordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}
