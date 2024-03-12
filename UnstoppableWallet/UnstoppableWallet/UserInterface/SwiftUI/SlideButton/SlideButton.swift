import SwiftUI
// https://github.com/no-comment/SlideButton

public struct SlideButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let callback: () async throws -> Void
    private let completion: () -> Void

    public typealias Styling = SlideButtonStyling
    private let styling: Styling

    @GestureState private var offset: CGFloat
    @State private var swipeState: SwipeState = .start

    public init(styling: Styling = .default, action: @escaping () async throws -> Void, completion: @escaping () -> Void) {
        callback = action
        self.completion = completion
        self.styling = styling

        _offset = .init(initialValue: 0)
    }

    @ViewBuilder
    private var label: some View {
        switch swipeState {
        case .start, .swiping:
            Text(styling.startText)
        case .success:
            Text(styling.successText)
        default:
            Text(styling.endText)
        }
    }

    public var body: some View {
        GeometryReader { reading in
            let calculatedOffset: CGFloat = swipeState == .swiping ? offset : (swipeState == .start ? 0 : (reading.size.width - styling.indicatorSize))
            ZStack(alignment: .leading) {
                styling.backgroundColor
                    .saturation(isEnabled ? 1 : 0)

                ZStack {
                    label
                        .font(styling.textFont)
                        .foregroundColor(styling.textColor)
                        .frame(maxWidth: max(0, reading.size.width), alignment: .center)
                        .padding(.horizontal, styling.indicatorSize)
                        .shimmerEffect(isEnabled && styling.textShimmers)

                    Capsule()
                        .fill(isEnabled ? styling.indicatorColor : .gray)
                        .frame(width: swipeState.userSlided ? styling.indicatorSize : calculatedOffset + styling.indicatorSize)
                        .frame(maxWidth: .infinity, alignment: swipeState.userSlided ? .trailing : .leading)
                        .animation(.interactiveSpring().speed(0.8), value: swipeState)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Circle()
                    .brightness(isEnabled ? styling.indicatorBrightness : 0)
                    .frame(width: styling.indicatorSize, height: styling.indicatorSize)
                    .foregroundColor(isEnabled ? styling.indicatorColor : .gray)
                    .overlay(content: {
                        ZStack {
                            ProgressView().progressViewStyle(.circular)
                                .tint(.themeDark)
                                .opacity(swipeState == .end ? 1 : 0)
                            Image(styling.indicatorSuccess)
                                .renderingMode(.template)
                                .foregroundColor(.themeDark)
                                .scaleEffect(swipeState == .success ? 1.0 : 0.1)
                                .animation(.easeInOut, value: swipeState)
                                .opacity(swipeState == .success ? 1 : 0)

                            Image(isEnabled ? styling.indicator : styling.indicatorDisabled)
                                .renderingMode(.template)
                                .foregroundColor(.themeDark)
                                .opacity(swipeState == .end || swipeState == .success ? 0 : 1)
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
            Button(action: {
                swipeState = .end

                Task {
                    try await callback()
                    swipeState = .start
                }
            }, label: {
                label
            })
            .disabled(swipeState != .start)
        }
    }

    private func clampValue(value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        max(minValue, min(maxValue, value))
    }

    private func progress(from start: Double, to end: Double, current: Double) -> Double {
        let clampedCurrent = max(min(current, end), start)
        return (clampedCurrent - start) / (end - start)
    }

    @MainActor
    private func set(state: SwipeState) {
        switch state {
        case .success:
            swipeState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completion()
            }
        default: swipeState = state
        }
    }

    private enum SwipeState {
        case start, swiping, end, success

        var userSlided: Bool {
            switch self {
            case .end, .success: return true
            default: return false
            }
        }
    }
}
