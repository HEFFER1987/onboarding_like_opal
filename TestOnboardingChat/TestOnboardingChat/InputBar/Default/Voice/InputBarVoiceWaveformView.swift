//
//  InputBarVoiceWaveformView.swift
//  TestOnboardingChat
//

import SwiftUI

struct InputBarVoiceWaveformView: View {
    let waveform: [Float]
    let progress: Double
    var isLiveRecording: Bool = false

    private let barWidth: CGFloat = 2
    private let barSpacing: CGFloat = 2
    private let minBarHalfHeight: CGFloat = 1.5
    private let cornerRadius: CGFloat = 1

    private let activeColor = Color.white.opacity(0.9)
    private let inactiveColor = Color.white.opacity(0.32)

    var body: some View {
        GeometryReader { geometry in
            let maxBars = max(1, Int((geometry.size.width + barSpacing) / (barWidth + barSpacing)))
            let samples = resolvedSamples(maxBars: maxBars)
            let maxHalfHeight = max(minBarHalfHeight, (geometry.size.height / 2) - 0.5)

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(samples) { sample in
                    let barProgress = Double(sample.displayIndex + 1) / Double(max(samples.count, 1))
                    let halfHeight = max(minBarHalfHeight, CGFloat(sample.value) * maxHalfHeight)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(barProgress <= progress ? activeColor : inactiveColor)
                        .frame(width: barWidth, height: halfHeight * 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isLiveRecording ? .trailing : .leading)
        }
        .transaction { $0.animation = nil }
    }

    private struct BarSample: Identifiable {
        let id: Int
        let value: Float
        let displayIndex: Int
    }

    private func resolvedSamples(maxBars: Int) -> [BarSample] {
        guard !waveform.isEmpty else { return [] }

        if isLiveRecording {
            let visibleCount = min(maxBars, waveform.count)
            guard visibleCount > 0 else { return [] }
            let startIndex = waveform.count - visibleCount
            return (startIndex..<waveform.count).enumerated().map { offset, index in
                BarSample(id: index, value: waveform[index], displayIndex: offset)
            }
        }

        let values: [Float]
        if waveform.count > maxBars {
            values = downsample(waveform, to: maxBars)
        } else if waveform.count < maxBars {
            values = upsample(waveform, to: maxBars)
        } else {
            values = waveform
        }

        return values.enumerated().map { index, value in
            BarSample(id: index, value: value, displayIndex: index)
        }
    }

    private func downsample(_ samples: [Float], to target: Int) -> [Float] {
        let chunkSize = Double(samples.count) / Double(target)
        return (0..<target).map { index in
            let start = Int(Double(index) * chunkSize)
            let end = min(samples.count, Int(Double(index + 1) * chunkSize))
            guard end > start else { return samples[min(start, samples.count - 1)] }
            return samples[start..<end].max() ?? 0.08
        }
    }

    private func upsample(_ samples: [Float], to target: Int) -> [Float] {
        guard samples.count > 1 else { return Array(repeating: samples[0], count: target) }

        return (0..<target).map { index in
            let position = Double(index) / Double(target - 1) * Double(samples.count - 1)
            let lower = Int(position.rounded(.down))
            let upper = min(samples.count - 1, lower + 1)
            let fraction = position - Double(lower)
            let lowerValue = Double(samples[lower])
            let upperValue = Double(samples[upper])
            return Float((1 - fraction) * lowerValue + fraction * upperValue)
        }
    }
}
