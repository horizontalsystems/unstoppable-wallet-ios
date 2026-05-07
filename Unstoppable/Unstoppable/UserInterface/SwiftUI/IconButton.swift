import SwiftUI

struct IconButton: View {
    let icon: String
    var style: ThemeButton.Style = .primary
    var mode: ThemeButton.Mode = .solid
    var size: ThemeButton.Size = .medium
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(icon).buttonIcon(size: size.iconSize)
        }
        .buttonStyle(Style(style: style, mode: mode, size: size))
    }

    private struct Style: ButtonStyle {
        let style: ThemeButton.Style
        let mode: ThemeButton.Mode
        let size: ThemeButton.Size

        @Environment(\.isEnabled) private var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(size: size.size)
                .foregroundColor(ThemeButton.foregroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .background(ThemeButton.backgroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .clipShape(Circle())
                .opacity(configuration.isPressed ? size.pressOpacity : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}
