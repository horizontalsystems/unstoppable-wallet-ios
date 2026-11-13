import SwiftUI

// https://github.com/no-comment/SlideButton

public struct SlideButton: View {
    private let callback: () async throws -> Void
    private let completion: () -> Void

    public typealias Styling = SlideButtonStyling
    private let styling: Styling
    private let identifier: String?

    private static let completionDelay: TimeInterval = 0.8

    @Environment(\.isEnabled) private var isEnabled
    @GestureState private var offset: CGFloat
    @State private var swipeState: SwipeState = .start

    public init(styling: Styling = .default, identifier: String? = nil, action: @escaping () async throws -> Void, completion: @escaping () -> Void) {
        callback = action
        self.completion = completion
        self.styling = styling
        self.identifier = identifier

        _offset = .init(initialValue: 0)
    }

    @ViewBuilder
    private var label: some View {
        switch swipeState {
        case .start, .swiping:
            ThemeText(styling.startText, style: styling.textStyle, colorStyle: styling.textColorStyle)
        case .success:
            ThemeText(styling.successText, style: styling.textStyle, colorStyle: styling.textColorStyle)
        default:
            ThemeText(styling.endText, style: styling.textStyle, colorStyle: styling.textColorStyle)
        }
    }

    public var body: some View {
        GeometryReader { reading in
            let calculatedOffset: CGFloat = swipeState == .swiping ? offset : (swipeState == .start ? 0 : (reading.size.width - styling.indicatorSize))
            ZStack(alignment: .leading) {
                styling.backgroundColor

                ZStack {
                    ThemeText(styling.startText, style: styling.textStyle, colorStyle: isEnabled ? styling.textColorStyle : styling.disabledColorStyle)
                        .frame(maxWidth: max(0, reading.size.width), alignment: .center)
                        .padding(.horizontal, styling.indicatorSize)
                        .opacity(titleOpacity(trackWidth: reading.size.width))
                        .animation(.easeInOut, value: swipeState)
                        .mask {
                            Rectangle()
                                .frame(width: max(0, reading.size.width - (calculatedOffset + styling.indicatorSize)))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .animation(.interactiveSpring().speed(0.8), value: swipeState)
                        }
                    // .shimmerEffect(styling.textShimmers) // it causes app crash on iOS 18

                    Capsule()
                        .fill(styling.indicatorColorStyle.color)
                        .opacity(isEnabled ? styling.fillOpacity : 0)
                        .frame(width: swipeState.isCommitted ? styling.indicatorSize : calculatedOffset + styling.indicatorSize)
                        .frame(maxWidth: .infinity, alignment: swipeState.isCommitted ? .trailing : .leading)
                        .animation(.interactiveSpring().speed(0.8), value: swipeState)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Circle()
                    .fill(isEnabled ? styling.indicatorColorStyle.color : styling.disabledColorStyle.color)
                    .brightness(styling.indicatorBrightness)
                    .frame(width: styling.indicatorSize, height: styling.indicatorSize)
                    .overlay(content: {
                        ZStack {
                            ProgressView().progressViewStyle(.circular)
                                .tint(styling.indicatorIconColorStyle.color)
                                .opacity(swipeState == .end ? 1 : 0)
                            ThemeImage(styling.indicatorSuccess, size: .iconSize24, colorStyle: styling.indicatorIconColorStyle)
                                .scaleEffect(swipeState == .success ? 1.0 : 0.1)
                                .animation(.easeInOut, value: swipeState)
                                .opacity(swipeState == .success ? 1 : 0)

                            ThemeImage(styling.indicator, size: .iconSize24, colorStyle: isEnabled ? styling.indicatorIconColorStyle : styling.disabledIconColorStyle)
                                .opacity(swipeState.isCommitted ? 0 : 1)
                        }
                    })
                    .offset(x: calculatedOffset)
                    .animation(.interactiveSpring().speed(0.8), value: swipeState)
                    .gesture(
                        DragGesture()
                            .updating($offset) { value, state, _ in
                                guard swipeState != .end else { return }

                                if swipeState == .start {
                                    DispatchQueue.main.async {
                                        swipeState = .swiping
                                    }
                                }

                                let val = value.translation.width

                                state = clampValue(value: val, min: 0, max: reading.size.width - styling.indicatorSize)
                            }
                            .onEnded { value in
                                guard swipeState == .swiping else { return }
                                set(state: .end)

                                let predictedVal = value.predictedEndTranslation.width
                                let val = value.translation.width

                                if predictedVal > reading.size.width
                                    || val > reading.size.width - styling.indicatorSize
                                {
                                    Task {
                                        do {
                                            try await callback()
                                            set(state: .success)
                                        } catch {
                                            set(state: .start)
                                        }
                                    }
                                } else {
                                    set(state: .start)
                                }
                            }
                    )
            }
            .mask { Capsule() }
        }
        .frame(height: styling.indicatorSize)
        .accessibilityRepresentation {
            let button = Button(action: {
                swipeState = .end

                Task {
                    try await callback()
                    swipeState = .start
                }
            }, label: {
                label
            })
            .disabled(swipeState != .start)

            if let identifier {
                button.accessibilityIdentifier(identifier)
            } else {
                button
            }
        }
    }

    private func clampValue(value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        max(minValue, min(maxValue, value))
    }

    private func progress(from start: Double, to end: Double, current: Double) -> Double {
        let clampedCurrent = max(min(current, end), start)
        return (clampedCurrent - start) / (end - start)
    }

    private func titleOpacity(trackWidth: CGFloat) -> Double {
        switch swipeState {
        case .start:
            return 1
        case .swiping:
            let travel = trackWidth - styling.indicatorSize
            guard travel > 0 else { return 0 }
            return 1 - progress(from: 0, to: travel, current: offset)
        case .end, .success:
            return 0
        }
    }

    @MainActor
    private func set(state: SwipeState) {
        switch state {
        case .success:
            swipeState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.completionDelay) {
                completion()
            }
        default: swipeState = state
        }
    }

    private enum SwipeState {
        case start, swiping, end, success

        var isCommitted: Bool {
            self == .end || self == .success
        }
    }
}
