import ComponentKit
import SwiftUI

struct PrimaryCircleButtonStyle: ButtonStyle {
    let style: Style

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: .heightButton, height: .heightButton)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .clipShape(Circle())
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case active
        case `default`
        case transparent

        init(style: PrimaryButton.Style) {
            switch style {
            case .active: self = .active
            case .default: self = .default
            case .transparent: self = .transparent
            }
        }

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .active: return isEnabled ? .themeLawrence : .themeAndy
            case .default: return isEnabled ? .themeTyler : .themeAndy
            case .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeAndy
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .active: return isEnabled ? (isPressed ? .themeOrange.pressed : .themeOrange) : .themeBlade
            case .default: return isEnabled ? (isPressed ? .themeLeah.pressed : .themeLeah) : .themeBlade
            case .transparent: return .clear
            }
        }
    }
}
