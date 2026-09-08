//
//  LocationMapZoom.swift
//  TestOnboardingChat
//

import CoreLocation
import MapKit

enum LocationMapZoomLevel: Equatable {
    case street
    case neighborhood
    case city
    case region

    var span: MKCoordinateSpan {
        switch self {
        case .street:
            MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        case .neighborhood:
            MKCoordinateSpan(latitudeDelta: 0.028, longitudeDelta: 0.028)
        case .city:
            MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        case .region:
            MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        }
    }

    static func forPlacemark(_ placemark: CLPlacemark) -> LocationMapZoomLevel {
        if placemark.subThoroughfare != nil || placemark.thoroughfare != nil {
            return .street
        }
        if placemark.subLocality != nil || placemark.locality != nil {
            return .city
        }
        if placemark.administrativeArea != nil {
            return .region
        }
        if placemark.country != nil {
            return .region
        }
        return .street
    }

    static func forMapItem(_ item: MKMapItem) -> LocationMapZoomLevel {
        if item.pointOfInterestCategory != nil {
            return .street
        }

        return forPlacemark(item.placemark)
    }

    static func level(for span: MKCoordinateSpan) -> LocationMapZoomLevel {
        let delta = max(span.latitudeDelta, span.longitudeDelta)

        switch delta {
        case ..<0.02:
            return .street
        case ..<0.06:
            return .neighborhood
        case ..<0.15:
            return .city
        default:
            return .region
        }
    }

    static func clampedSpan(_ span: MKCoordinateSpan) -> MKCoordinateSpan {
        MKCoordinateSpan(
            latitudeDelta: min(max(span.latitudeDelta, 0.008), 0.22),
            longitudeDelta: min(max(span.longitudeDelta, 0.008), 0.22)
        )
    }

    static func resolvedSpan(preferred level: LocationMapZoomLevel, fallback: MKCoordinateSpan) -> MKCoordinateSpan {
        let preferred = level.span
        let fallbackDelta = max(fallback.latitudeDelta, fallback.longitudeDelta)
        let preferredDelta = max(preferred.latitudeDelta, preferred.longitudeDelta)

        if abs(fallbackDelta - preferredDelta) < 0.004 {
            return clampedSpan(fallback)
        }

        return preferred
    }

    private static func isUsableSearchSpan(_ span: MKCoordinateSpan) -> Bool {
        let delta = max(span.latitudeDelta, span.longitudeDelta)
        return delta >= 0.004 && delta <= 0.35
    }
}
