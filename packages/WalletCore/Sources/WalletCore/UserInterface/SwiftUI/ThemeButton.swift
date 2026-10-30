import SwiftUI

struct ThemeButton: View {
    let text: String
    var icon: String? = nil
    var iconColorStyle: ColorStyle? = nil
    var spinner: Bool = false
    // a determinate spinner, as a transaction in progress shows in the transaction list
    var progress: Double? = nil
    var style: ThemeButton.Style = .primary
    var mode: ThemeButton.Mode = .solid
    var size: ThemeButton.Size = .medium
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.iconSpacing) {
                if let progress {
                    ProgressView(value: max(0.1, progress))
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(size: size.iconSize)
                        .spinning()
                } else if spinner {
                    ProgressView()
                }

                if let icon {
                    Image(icon).buttonIcon(size: size.iconSize).foregroundColor(ifSet: iconColorStyle)
                }

                Text(text)
                    .font(size.textStyle.font)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                .padding(.horizontal, .margin16)
                .frame(height: size.size)
                .foregroundColor(ThemeButton.foregroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .background(ThemeButton.backgroundColor(style: style, mode: mode, size: size, isEnabled: isEnabled))
                .clipShape(Capsule(style: .continuous))
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
            case .medium: return .buttonSize56
            case .small: return .buttonSize32
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .medium: return .iconSize24
            case .small: return .iconSize20
            }
        }

        var iconSpacing: CGFloat {
            switch self {
            case .medium: return .margin8
            case .small: return .margin4
            }
        }
    }

    static func foregroundColor(style: Style, mode: Mode, size: Size, isEnabled: Bool) -> Color {
        switch mode {
        case .solid:
            guard isEnabled else {
                return .themeAndy
            }

            switch (style, size) {
            case (.secondary, .small): return .themeLeah
            default: return .themeLawrence
            }
        case .transparent:
            guard isEnabled else {
                return .themeGray
            }

            switch style {
            case .primary: return .themeJacob
            case .secondary: return .themeLeah
            }
        }
    }

    static func backgroundColor(style: Style, mode: Mode, size: Size, isEnabled: Bool) -> Color {
        switch mode {
        case .solid:
            guard isEnabled else {
                return .themeBlade
            }

            switch style {
            case .primary: return .themeJacob
            case .secondary:
                switch size {
                case .medium: return .themeLeah
                case .small: return .themeBlade
                }
            }
        case .transparent: return .clear
        }
    }
}
