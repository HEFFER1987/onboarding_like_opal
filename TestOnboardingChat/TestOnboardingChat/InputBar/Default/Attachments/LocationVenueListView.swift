//
//  LocationVenueListView.swift
//  TestOnboardingChat
//

import CoreLocation
import SwiftUI

struct LocationVenueListView: View {
    let currentAddress: String
    let isGeocoding: Bool
    let venues: [LocationVenue]
    let isLoadingVenues: Bool
    let onSelectCurrentLocation: () -> Void
    let onSelectVenue: (LocationVenue) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                currentLocationRow

                if isLoadingVenues && venues.isEmpty {
                    loadingRow
                } else if venues.isEmpty {
                    emptyRow
                } else {
                    sectionHeader("Nearby Places")
                    ForEach(venues) { venue in
                        venueRow(venue)
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var currentLocationRow: some View {
        Button(action: onSelectCurrentLocation) {
            HStack(spacing: 12) {
                iconCircle(systemName: "mappin.and.ellipse", tint: LocationPickerColors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Send this location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(isGeocoding ? "Locating…" : currentAddress)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func venueRow(_ venue: LocationVenue) -> some View {
        Button {
            onSelectVenue(venue)
        } label: {
            HStack(spacing: 12) {
                iconCircle(systemName: "building.2.fill", tint: .white.opacity(0.85))

                VStack(alignment: .leading, spacing: 2) {
                    Text(venue.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let subtitle = venue.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Text(formattedDistance(venue.distanceMeters))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.38))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white.opacity(0.6))
            Text("Searching nearby places…")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var emptyRow: some View {
        Text("No places found nearby")
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
    }

    private func iconCircle(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(Color.white.opacity(0.1), in: Circle())
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1_000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1_000)
    }
}
