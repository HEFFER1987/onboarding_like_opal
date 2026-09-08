//
//  LocationService.swift
//  TestOnboardingChat
//

import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var errorMessage: String?
    var isLocating = false

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            true
        default:
            false
        }
    }

    var isAccessDenied: Bool {
        switch authorizationStatus {
        case .denied, .restricted:
            true
        default:
            false
        }
    }

    private let manager = CLLocationManager()
    private var isUpdating = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func start() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied"
        @unknown default:
            errorMessage = "Location unavailable"
        }
    }

    func stop() {
        guard isUpdating else { return }
        manager.stopUpdatingLocation()
        isUpdating = false
        isLocating = false
    }

    func requestCurrentLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied"
        @unknown default:
            errorMessage = "Location unavailable"
        }
    }

    private func beginUpdatingLocation() {
        isLocating = true
        guard !isUpdating else { return }
        manager.startUpdatingLocation()
        isUpdating = true
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                beginUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            currentLocation = location
            errorMessage = nil
            isLocating = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let clError = error as? CLError else { return }

            switch clError.code {
            case .denied:
                errorMessage = "Location access denied"
                isLocating = false
            case .locationUnknown, .network:
                // Transient — Core Location may retry via startUpdatingLocation().
                break
            default:
                errorMessage = "Unable to determine location"
                isLocating = false
            }
        }
    }
}
