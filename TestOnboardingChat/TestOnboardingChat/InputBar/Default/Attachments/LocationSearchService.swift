//
//  LocationSearchService.swift
//  TestOnboardingChat
//

import CoreLocation
import MapKit

@MainActor
final class LocationSearchService {
    private let geocoder = LocationGeocoder()
    private var task: Task<Void, Never>?

    func search(
        query: String,
        near coordinate: CLLocationCoordinate2D,
        referenceLocation: CLLocation?,
        completion: @escaping @MainActor ([LocationSearchResult]) -> Void
    ) {
        task?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }

        task = Task {
            let localResults = await searchWithLocalSearch(
                query: trimmed,
                near: coordinate,
                referenceLocation: referenceLocation
            )

            guard !Task.isCancelled else { return }

            var results = localResults
            if results.count < 4 {
                let geocoded = await geocoder.forwardGeocode(
                    address: trimmed,
                    near: coordinate
                )
                guard !Task.isCancelled else { return }
                results = mergeResults(primary: results, secondary: geocoded)
            }

            completion(Array(results.prefix(16)))
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        geocoder.cancelForward()
    }

    private func searchWithLocalSearch(
        query: String,
        near coordinate: CLLocationCoordinate2D,
        referenceLocation: CLLocation?
    ) async -> [LocationSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 80_000,
            longitudinalMeters: 80_000
        )
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard !Task.isCancelled else { return [] }

            let origin = referenceLocation
                ?? CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            return response.mapItems.compactMap { item in
                makeSearchResult(from: item, origin: origin)
            }
        } catch {
            guard !Task.isCancelled else { return [] }
            return []
        }
    }

    private func makeSearchResult(from item: MKMapItem, origin: CLLocation) -> LocationSearchResult? {
        let placemark = item.placemark
        let itemCoordinate = placemark.coordinate

        guard CLLocationCoordinate2DIsValid(itemCoordinate) else { return nil }
        guard itemCoordinate.latitude != 0 || itemCoordinate.longitude != 0 else { return nil }

        let title = Self.displayTitle(for: item)
        guard !title.isEmpty else { return nil }

        let subtitle = Self.displaySubtitle(for: item, title: title)
        let kind: LocationSearchResult.Kind = item.pointOfInterestCategory == nil ? .address : .venue
        let key = Self.coordinateKey(itemCoordinate)

        return LocationSearchResult(
            id: "\(kind)-\(key)-\(title)",
            title: title,
            subtitle: subtitle,
            coordinate: itemCoordinate,
            kind: kind,
            zoomLevel: LocationMapZoomLevel.forMapItem(item)
        )
    }

    private func mergeResults(
        primary: [LocationSearchResult],
        secondary: [LocationSearchResult]
    ) -> [LocationSearchResult] {
        var merged = primary
        var seen = Set(primary.map(\.id))

        for result in secondary where seen.insert(result.id).inserted {
            merged.append(result)
        }

        return merged
    }

    private static func displayTitle(for item: MKMapItem) -> String {
        if let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }

        if let title = item.placemark.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }

        return LocationGeocoder.formatPlacemarkTitle(item.placemark)
    }

    private static func displaySubtitle(for item: MKMapItem, title: String) -> String? {
        var parts: [String] = []

        if let thoroughfare = item.placemark.thoroughfare,
           !title.localizedCaseInsensitiveContains(thoroughfare) {
            parts.append(thoroughfare)
        }

        if let locality = item.placemark.locality,
           !parts.contains(locality) {
            parts.append(locality)
        }

        if let administrativeArea = item.placemark.administrativeArea,
           !parts.contains(administrativeArea) {
            parts.append(administrativeArea)
        }

        let subtitle = parts.joined(separator: ", ")
        return subtitle.isEmpty ? nil : subtitle
    }

    private static func coordinateKey(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f-%.5f", coordinate.latitude, coordinate.longitude)
    }
}
