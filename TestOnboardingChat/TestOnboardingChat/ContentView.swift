//
//  ContentView.swift
//  TestOnboardingChat
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        OnboardingView()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
