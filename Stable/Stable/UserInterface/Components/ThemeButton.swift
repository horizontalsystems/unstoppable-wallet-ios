import SwiftUI

struct ThemeButton: View {
    let text: LocalizedStringResource
    var icon: String? = nil
    var spinner: Bool = false
    var style: ThemeButton.Style = .primary
    var mode: ThemeButton.Mode = .solid
    var size: ThemeButton.Size = .medium
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.iconSpacing) {
                if spinner {
                    ProgressView()
                }

                if let icon {
                    Image(icon)
                        .resizable()
                        .frame(size: size.iconSize)
                }

                Text(text)
                    .font(size.textStyle.font)
            }
            .offset(x: 0, y: size == .small ? -1 : 0)
        }
        .buttonStyle(ThemeButtonStyle(style: style, mode: mode, size: size))
    }

    private struct ThemeButtonStyle: ButtonStyle {
        let style: ThemeButton.Style
        let mode: ThemeButton.Mode
        let size: ThemeButton.Size

        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: size == .medium ? .infinity : nil)
                .padding(.horizontal, 16)
                .frame(height: size.size)
                .foregroundColor(ThemeButton.foregroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .background(ThemeButton.backgroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
                .opacity(configuration.isPressed ? 0.6 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

extension ThemeButton {
    enum Style {
        case primary
        case secondary
    }

    enum Mode {
        case solid
        case transparent
    }

    enum Size {
        case medium
        case small

        var textStyle: TextStyle {
            switch self {
            case .medium: return .headline2
            case .small: return .captionSB
            }
        }

        var size: CGFloat {
            switch self {
            case .medium: return 56
            case .small: return 32
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .medium: return 24
            case .small: return 16
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .medium: return 24
            case .small: return 20
            }
        }

        var iconSpacing: CGFloat {
            switch self {
            case .medium: return 8
            case .small: return 4
            }
        }
    }

    static func foregroundColor(style: Style, mode: Mode, size _: Size, isEnabled: Bool) -> Color {
        switch mode {
        case .solid:
            guard isEnabled else {
                return .themeLimeText.opacity(0.2)
            }

            switch style {
            case .primary: return .black
            case .secondary: return .themeLimeText
            }
        case .transparent:
            guard isEnabled else {
                return .themeLimeText.opacity(0.15)
            }

            return .themeLimeText
        }
    }

    static func backgroundColor(style: Style, mode: Mode, size _: Size, isEnabled: Bool) -> Color {
        switch mode {
        case .solid:
            guard isEnabled else {
                return .themeLimeD.opacity(0.2)
            }

            switch style {
            case .primary: return .themeLimeD
            case .secondary: return .themeLimeD.opacity(0.15)
            }
        case .transparent: return .clear
        }
    }
}
