import SwiftUI
import ThemeKit

struct NumPadView: View {
    @Binding var digits: [Int]
    @Binding var biometryType: BiometryType?
    @Binding var disabled: Bool

    let onTapDigit: (Int) -> Void
    let onTapBackspace: () -> Void
    var onTapBiometry: (() -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: .margin16) {
            ForEach(Array(digits.prefix(9).enumerated()), id: \.offset) { _, digit in
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            if let biometryType {
                Button(action: {
                    onTapBiometry?()
                }) {
                    Image(biometryType.iconName).renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
                .disabled(disabled)
            } else {
                Text("")
            }

            if let digit = digits.last {
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            Button(action: {
                onTapBackspace()
            }) {
                Image("backspace_24").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
            .disabled(disabled)
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
            .disabled(disabled)
            .animation(.easeOut(duration: 0.2), value: digit)
        }
    }

    struct NumPadButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(isEnabled ? .themeLeah : .themeSteel20)
                .background(configuration.isPressed ? Color.themeSteel20 : Color.themeTyler)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.themeSteel20, lineWidth: .heightOneDp))
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
