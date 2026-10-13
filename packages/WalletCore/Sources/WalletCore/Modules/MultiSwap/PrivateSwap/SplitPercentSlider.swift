import SwiftUI
import UIKit

// Two-sided split slider: the left label is the share of Address 1, the right one the share of Address 2.
// Moves in whole steps only; the binding is written only when the step changes.
struct SplitPercentSlider: View {
    @Binding var percent: Int
    var range: ClosedRange<Int> = SplitSwapViewModel.percentRange
    var step: Int = SplitSwapViewModel.percentStep

    private let thumbSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 12) {
            ThemeText("\(percent)%", style: .subhead, colorStyle: .secondary)
                .monospacedDigit()

            GeometryReader { geometry in
                let usableWidth = max(geometry.size.width - thumbSize, 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeBlade)
                        .frame(height: 4)

                    Circle()
                        .fill(Color.themeJacob)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Capsule()
                                .fill(Color.themeDark)
                                .frame(width: 12, height: 2)
                        )
                        .offset(x: usableWidth * fraction)
                }
                .frame(width: geometry.size.width, height: thumbSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let position = min(max(value.location.x - thumbSize / 2, 0), usableWidth)
                            let span = Double(range.upperBound - range.lowerBound)

                            update(to: Double(range.lowerBound) + Double(position / usableWidth) * span)
                        }
                )
            }
            .frame(height: thumbSize)

            ThemeText("\(100 - percent)%", style: .subhead, colorStyle: .secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(percent)% / \(100 - percent)%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: update(to: Double(percent + step))
            case .decrement: update(to: Double(percent - step))
            @unknown default: ()
            }
        }
    }

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound

        guard span > 0 else {
            return 0
        }

        return CGFloat(percent - range.lowerBound) / CGFloat(span)
    }

    private func update(to value: Double) {
        let snapped = Int((value / Double(step)).rounded()) * step
        let newPercent = min(max(snapped, range.lowerBound), range.upperBound)

        guard newPercent != percent else {
            return
        }

        percent = newPercent
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
