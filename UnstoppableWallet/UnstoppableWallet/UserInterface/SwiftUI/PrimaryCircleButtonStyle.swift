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
            case .yellow: return isEnabled ? .themeDark : .themeGray50
            case .red, .gray: return isEnabled ? .themeClaude : .themeGray50
            case .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeGray50
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .yellow: return isEnabled ? (isPressed ? .themeYellow50 : .themeYellow) : .themeSteel20
            case .red: return isEnabled ? (isPressed ? .themeRed50 : .themeLucian) : .themeSteel20
            case .gray: return isEnabled ? (isPressed ? .themeNina : .themeLeah) : .themeSteel20
            case .transparent: return .clear
            }
        }
    }
}
