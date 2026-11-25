import SwiftUI

struct NumPadView: View {
    @Binding var digits: [Int]
    @Binding var biometryType: BiometryType?
    let disabled: Bool
    var backspaceDisabled: Bool = false

    let onTapDigit: (Int) -> Void
    let onTapBackspace: () -> Void
    var onTapBiometry: (() -> Void)?

    private static let backspaceIcon = "arrow_m_left"

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
            ForEach(Array(digits.prefix(9).enumerated()), id: \.offset) { _, digit in
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            if let biometryType {
                Button(action: {
                    onTapBiometry?()
                }) {
                    Color.clear
                }
                .buttonStyle(NumPadButtonStyle(kind: .icon(biometryType.iconName)))
                .numPadCell()
                .accessibilityLabel(biometryType.title)
                .accessibilityIdentifier(TestTags.pinKeyBiometry)
                .disabled(disabled)
            } else {
                Color.clear
                    .numPadCell()
            }

            if let digit = digits.last {
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            Button(action: {
                onTapBackspace()
            }) {
                Color.clear
            }
            .buttonStyle(NumPadButtonStyle(kind: .icon(Self.backspaceIcon)))
            .numPadCell()
            .accessibilityLabel("button.delete".localized)
            .accessibilityIdentifier(TestTags.pinKeyDelete)
            .disabled(disabled || backspaceDisabled)
        }
    }

    struct NumberView: View {
        let digit: Int
        let disabled: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: {
                onTap()
            }) {
                Color.clear
            }
            .buttonStyle(NumPadButtonStyle(kind: .text(String(digit))))
            .numPadCell()
            .accessibilityLabel(String(digit))
            .accessibilityIdentifier(TestTags.pinKey(digit))
            .disabled(disabled)
            .animation(.easeOut(duration: 0.2), value: digit)
        }
    }

    struct NumPadButtonStyle: ButtonStyle {
        // pressed sizes from the design: digit 36 -> 48, icon 24 -> 36
        private static let textPressedScale: CGFloat = 48 / 36
        private static let iconPressedScale: CGFloat = 36 / 24
        // the press-in tracks the finger; the release settles back smoothly
        private static let pressAnimation: Animation = .easeOut(duration: 0.1)
        private static let releaseAnimation: Animation = .easeOut(duration: 0.3)

        let kind: Kind

        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            ZStack {
                configuration.label

                content(isPressed: configuration.isPressed)
                    .animation(configuration.isPressed ? Self.pressAnimation : Self.releaseAnimation, value: configuration.isPressed)
            }
            // the label is clear, so without a shape only the glyph takes touches; the whole cell is the button
            .contentShape(Rectangle())
        }

        @ViewBuilder private func content(isPressed: Bool) -> some View {
            switch kind {
            case let .text(digit):
                ZStack {
                    ThemeText(digit, style: .title2R, colorStyle: .primary, dimmed: !isEnabled)
                        .opacity(isPressed ? 0 : 1)

                    ThemeText(digit, style: .title2, colorStyle: .primary, dimmed: !isEnabled)
                        .opacity(isPressed ? 1 : 0)
                }
                .scaleEffect(isPressed ? Self.textPressedScale : 1)
            case let .icon(name):
                ThemeImage(name, size: .iconSize24, colorStyle: isEnabled ? .primary : .andy)
                    .scaleEffect(isPressed ? Self.iconPressedScale : 1)
            }
        }

        enum Kind {
            case text(String)
            case icon(String)
        }
    }
}

private extension View {
    func numPadCell() -> some View {
        frame(maxWidth: .infinity)
            .frame(height: .margin64)
    }
}
