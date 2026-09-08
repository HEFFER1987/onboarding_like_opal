//
//  ComposerVoiceWaveformView.swift
//  TestOnboardingChat
//

import SwiftUI

struct ComposerVoiceWaveformView: View {
    let waveform: [Float]
    let progress: Double

    private let maxBars = 36

    var body: some View {
        GeometryReader { geometry in
            let samples = downsampledWaveform(waveform, maxBars: maxBars)
            let barWidth = max(2, (geometry.size.width - CGFloat(samples.count - 1) * 2) / CGFloat(samples.count))

            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    let barProgress = Double(index + 1) / Double(samples.count)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(barProgress <= progress ? 0.85 : 0.3))
                        .frame(width: barWidth, height: max(4, CGFloat(sample) * 22))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func downsampledWaveform(_ samples: [Float], maxBars: Int) -> [Float] {
        guard !samples.isEmpty else { return Array(repeating: 0.25, count: maxBars) }
        guard samples.count > maxBars else { return samples }

        let chunkSize = Double(samples.count) / Double(maxBars)
        return (0..<maxBars).map { index in
            let start = Int(Double(index) * chunkSize)
            let end = min(samples.count, Int(Double(index + 1) * chunkSize))
            guard end > start else { return samples[min(start, samples.count - 1)] }
            let slice = samples[start..<end]
            return slice.max() ?? 0.25
        }
    }
}
