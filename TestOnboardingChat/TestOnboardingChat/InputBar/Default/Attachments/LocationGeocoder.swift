//
//  LocationGeocoder.swift
//  TestOnboardingChat
//

import CoreLocation
import Foundation

@MainActor
final class LocationGeocoder {
    private var reverseTask: Task<Void, Never>?
    private var forwardTask: Task<Void, Never>?

    func reverseGeocode(
        coordinate: CLLocationCoordinate2D,
        onUpdate: @escaping @MainActor (String?) -> Void
    ) {
        reverseTask?.cancel()
        reverseTask = Task {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard !Task.isCancelled else { return }
                onUpdate(Self.formatAddress(placemarks.first))
            } catch {
                guard !Task.isCancelled else { return }
                onUpdate(nil)
            }
        }
    }

    func forwardGeocode(
        address: String,
        onUpdate: @escaping @MainActor ([CLPlacemark]) -> Void
    ) {
        forwardGeocode(address: address, near: nil, onUpdate: onUpdate)
    }

    func forwardGeocode(
        address: String,
        near coordinate: CLLocationCoordinate2D?,
        onUpdate: @escaping @MainActor ([CLPlacemark]) -> Void
    ) {
        forwardTask?.cancel()
        forwardTask = Task {
            let geocoder = CLGeocoder()
            let region = coordinate.map {
                CLCircularRegion(
                    center: $0,
                    radius: 80_000,
                    identifier: "location-search"
                )
            }

            do {
                let placemarks = try await geocoder.geocodeAddressString(
                    address,
                    in: region,
                    preferredLocale: Locale.current
                )
                guard !Task.isCancelled else { return }
                onUpdate(placemarks)
            } catch {
                guard !Task.isCancelled else { return }
                onUpdate([])
            }
        }
    }

    func forwardGeocode(
        address: String,
        near coordinate: CLLocationCoordinate2D
    ) async -> [LocationSearchResult] {
        await withCheckedContinuation { continuation in
            forwardGeocode(address: address, near: coordinate) { placemarks in
                let results = placemarks.compactMap { placemark -> LocationSearchResult? in
                    guard let location = placemark.location else { return nil }
                    let itemCoordinate = location.coordinate
                    guard CLLocationCoordinate2DIsValid(itemCoordinate) else { return nil }

                    let title = Self.formatPlacemarkTitle(placemark)
                    let key = String(format: "%.5f-%.5f", itemCoordinate.latitude, itemCoordinate.longitude)

                    return LocationSearchResult(
                        id: "geocode-\(key)-\(title)",
                        title: title,
                        subtitle: Self.formatPlacemarkSubtitle(placemark),
                        coordinate: itemCoordinate,
                        kind: .address,
                        zoomLevel: LocationMapZoomLevel.forPlacemark(placemark)
                    )
                }
                continuation.resume(returning: results)
            }
        }
    }

    func cancelForward() {
        forwardTask?.cancel()
        forwardTask = nil
    }

    func cancel() {
        reverseTask?.cancel()
        reverseTask = nil
        cancelForward()
    }

    static func formatAddress(_ placemark: CLPlacemark?) -> String? {
        guard let placemark else { return nil }

        if let street = placemark.thoroughfare {
            if let city = placemark.locality {
                return "\(street), \(city)"
            }
            return street
        }

        if let name = placemark.name, !name.isEmpty {
            return name
        }

        if let city = placemark.locality {
            return city
        }

        if let country = placemark.country {
            return country
        }

        return nil
    }

    static func formatPlacemarkTitle(_ placemark: CLPlacemark) -> String {
        if let name = placemark.name, !name.isEmpty {
            return name
        }
        if let thoroughfare = placemark.thoroughfare {
            return thoroughfare
        }
        if let locality = placemark.locality {
            return locality
        }
        if let country = placemark.country {
            return country
        }
        return "Address"
    }

    static func formatPlacemarkSubtitle(_ placemark: CLPlacemark) -> String? {
        var parts: [String] = []

        if let thoroughfare = placemark.thoroughfare,
           placemark.name != thoroughfare {
            parts.append(thoroughfare)
        }
        if let locality = placemark.locality {
            parts.append(locality)
        }
        if let country = placemark.country {
            parts.append(country)
        }

        let subtitle = parts.joined(separator: ", ")
        return subtitle.isEmpty ? nil : subtitle
    }
}
