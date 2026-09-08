//
//  LocationPickerPinView.swift
//  TestOnboardingChat
//

import SwiftUI

struct LocationPickerPinView: View {
    var isRaised: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(LocationPickerColors.pinFill)
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: .black.opacity(0.28),
                        radius: isRaised ? 10 : 4,
                        y: isRaised ? 8 : 2
                    )

                Image(systemName: "mappin")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: -2)
            }
            .offset(y: isRaised ? -18 : 0)

            Ellipse()
                .fill(Color.black.opacity(isRaised ? 0.12 : 0.22))
                .frame(width: isRaised ? 6 : 10, height: isRaised ? 3 : 4)
                .offset(y: isRaised ? 6 : 2)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isRaised)
        .allowsHitTesting(false)
    }
}
