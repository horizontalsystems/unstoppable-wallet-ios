import SwiftUI
import ThemeKit

struct NumPadView: View {
    @Binding var digits: [Int]
    @Binding var biometryType: BiometryType?

    let onTapDigit: (Int) -> Void
    let onTapBackspace: () -> Void
    var onTapBiometry: (() -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: .margin16) {
            ForEach(Array(digits.prefix(9).enumerated()), id: \.offset) { _, digit in
                NumberView(digit: digit) { onTapDigit(digit) }
            }

            if let biometryType {
                Button(action: {
                    onTapBiometry?()
                }) {
                    Image(biometryType.iconName).themeIcon()
                }
            } else {
                Text("")
            }

            if let digit = digits.last {
                NumberView(digit: digit) { onTapDigit(digit) }
            }

            Button(action: {
                onTapBackspace()
            }) {
                Image("backspace_24").themeIcon()
            }
        }
        .frame(width: 280)
    }

    struct NumberView: View {
        let digit: Int
        let onTap: () -> Void

        var body: some View {
            Button(action: {
                onTap()
            }) {
                Text(String(digit))
                    .font(.themeTitle2R)
                    .foregroundColor(.themeLeah)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(NumPadButtonStyle())
            .animation(.easeOut, value: digit)
        }
    }

    struct NumPadButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color.themeSteel20 : Color.clear)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.themeSteel20, lineWidth: .heightOneDp))
                .animation(.easeOut, value: configuration.isPressed)
        }
    }
}
