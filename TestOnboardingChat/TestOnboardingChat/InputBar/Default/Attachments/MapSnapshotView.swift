//
//  MapSnapshotView.swift
//  TestOnboardingChat
//

import MapKit
import SwiftUI

struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D
    var size: CGSize = CGSize(width: 144, height: 144)

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.45))
                    }
            }
        }
        .task(id: coordinateKey) {
            image = await makeSnapshot()
        }
    }

    private var coordinateKey: String {
        String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude)
    }

    private func makeSnapshot() async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        options.size = size
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        return await withCheckedContinuation { continuation in
            snapshotter.start { snapshot, _ in
                continuation.resume(returning: snapshot?.image)
            }
        }
    }
}
