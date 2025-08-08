import SwiftUI

struct DropdownButton: View {
    let text: String
    var style: ThemeButton.Style = .secondary
    var mode: ThemeButton.Mode = .solid
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(text)
                    .font(ThemeButton.Size.small.textStyle.font)
                    .offset(x: 0, y: -1)

                Image("arrow_s_down").buttonIcon(size: ThemeButton.Size.small.iconSize)
            }
        }
        .buttonStyle(Style(style: style, mode: mode))
    }

    private struct Style: ButtonStyle {
        let style: ThemeButton.Style
        let mode: ThemeButton.Mode

        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.leading, .margin16)
                .padding(.trailing, 10)
                .frame(height: ThemeButton.Size.small.size)
                .foregroundColor(ThemeButton.foregroundColor(style: style, mode: mode, size: .small, isEnabled: isEnabled))
                .background(ThemeButton.backgroundColor(style: style, mode: mode, size: .small, isEnabled: isEnabled))
                .clipShape(Capsule(style: .continuous))
                .opacity(configuration.isPressed ? 0.6 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}
