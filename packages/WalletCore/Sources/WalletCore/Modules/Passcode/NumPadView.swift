import SwiftUI

struct NumPadView: View {
    @Binding var digits: [Int]
    @Binding var biometryType: BiometryType?
    @Binding var disabled: Bool

    let onTapDigit: (Int) -> Void
    let onTapBackspace: () -> Void
    var onTapBiometry: (() -> Void)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: .margin16) {
            ForEach(Array(digits.prefix(9).enumerated()), id: \.offset) { _, digit in
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            if let biometryType {
                IconButton(icon: biometryType.iconName, style: .secondary, mode: .transparent, size: .medium) {
                    onTapBiometry?()
                }
                .disabled(disabled)
            } else {
                Text("")
            }

            if let digit = digits.last {
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            IconButton(icon: "backspace", style: .secondary, mode: .transparent, size: .medium) {
                onTapBackspace()
            }
            .disabled(disabled)
            .accessibilityIdentifier(TestTags.pinKeyDelete)
        }
        .frame(width: 280)
    }

    struct NumberView: View {
        let digit: Int
        let disabled: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: {
                onTap()
            }) {
                Text(String(digit))
                    .font(.themeTitle2R)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(NumPadButtonStyle())
            .accessibilityIdentifier(TestTags.pinKey(digit))
            .disabled(disabled)
            .animation(.easeOut(duration: 0.2), value: digit)
        }
    }

    struct NumPadButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(isEnabled ? .themeLeah : .themeBlade)
                .background(configuration.isPressed ? Color.themeBlade : Color.themeTyler)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.themeBlade, lineWidth: .heightOneDp))
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
