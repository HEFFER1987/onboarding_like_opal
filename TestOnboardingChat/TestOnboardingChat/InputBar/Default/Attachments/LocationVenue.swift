//
//  LocationVenue.swift
//  TestOnboardingChat
//

import CoreLocation
import MapKit

struct LocationVenue: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: CLLocationDistance

    static func == (lhs: LocationVenue, rhs: LocationVenue) -> Bool {
        lhs.id == rhs.id
    }
}

struct LocationSearchResult: Identifiable, Equatable {
    enum Kind: Equatable {
        case address
        case venue
    }

    let id: String
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
    let zoomLevel: LocationMapZoomLevel

    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class LocationVenueSearchService {
    private var task: Task<Void, Never>?

    func search(
        query: String? = nil,
        near coordinate: CLLocationCoordinate2D,
        referenceLocation: CLLocation?,
        completion: @escaping @MainActor ([LocationVenue]) -> Void
    ) {
        task?.cancel()
        task = Task {
            let request = MKLocalSearch.Request()
            let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasQuery = trimmedQuery.map { !$0.isEmpty } ?? false

            if hasQuery, let trimmedQuery {
                request.naturalLanguageQuery = trimmedQuery
                request.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 50_000,
                    longitudinalMeters: 50_000
                )
                request.resultTypes = [.pointOfInterest, .address]
            } else {
                request.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1_500,
                    longitudinalMeters: 1_500
                )
                request.resultTypes = .pointOfInterest
            }

            let search = MKLocalSearch(request: request)

            do {
                let response = try await search.start()
                guard !Task.isCancelled else { return }

                let origin = referenceLocation ?? CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let venues = response.mapItems
                    .prefix(14)
                    .compactMap { item -> LocationVenue? in
                        let placemark = item.placemark
                        let venueCoordinate = placemark.coordinate
                        guard CLLocationCoordinate2DIsValid(venueCoordinate) else { return nil }

                        let name = Self.displayName(for: item)
                        guard !name.isEmpty else { return nil }

                        let distance = CLLocation(
                            latitude: venueCoordinate.latitude,
                            longitude: venueCoordinate.longitude
                        )
                        .distance(from: origin)

                        var subtitleParts: [String] = []
                        if let thoroughfare = placemark.thoroughfare {
                            subtitleParts.append(thoroughfare)
                        } else if let locality = placemark.locality {
                            subtitleParts.append(locality)
                        }

                        return LocationVenue(
                            id: "\(venueCoordinate.latitude)-\(venueCoordinate.longitude)-\(name)",
                            name: name,
                            subtitle: subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: ", "),
                            coordinate: venueCoordinate,
                            distanceMeters: distance
                        )
                    }

                let sortedVenues: [LocationVenue]
                if hasQuery {
                    sortedVenues = Array(venues)
                } else {
                    sortedVenues = venues.sorted { $0.distanceMeters < $1.distanceMeters }
                }

                completion(sortedVenues)
            } catch {
                guard !Task.isCancelled else { return }
                completion([])
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    private static func displayName(for item: MKMapItem) -> String {
        if let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }

        if let title = item.placemark.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }

        return LocationGeocoder.formatPlacemarkTitle(item.placemark)
    }
}
