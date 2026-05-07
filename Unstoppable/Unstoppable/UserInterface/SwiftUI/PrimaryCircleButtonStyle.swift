
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
        case yellow
        case red
        case gray
        case transparent

        init(style: PrimaryButton.Style) {
            switch style {
            case .yellow: self = .yellow
            case .red: self = .red
            case .gray: self = .gray
            case .transparent: self = .transparent
            }
        }

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .yellow: return isEnabled ? .themeDark : .themeAndy
            case .red, .gray: return isEnabled ? .themeClaude : .themeAndy
            case .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeAndy
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .yellow: return isEnabled ? (isPressed ? .themeYellow50 : .themeYellow) : .themeBlade
            case .red: return isEnabled ? (isPressed ? .themeRed50 : .themeLucian) : .themeBlade
            case .gray: return isEnabled ? (isPressed ? .themeNina : .themeLeah) : .themeBlade
            case .transparent: return .clear
            }
        }
    }
}
