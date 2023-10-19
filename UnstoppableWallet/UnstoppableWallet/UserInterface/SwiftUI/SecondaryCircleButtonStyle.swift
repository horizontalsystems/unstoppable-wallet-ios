import SwiftUI

struct SecondaryCircleButtonStyle: ButtonStyle {
    let style: Style

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
                .padding(.margin4)
                .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
                .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
                .clipShape(Circle())
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case `default`
        case transparent
        case red

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeGray50
            case .transparent: return isEnabled ? (isPressed ? .themeGray50 : .themeGray) : .themeGray50
            case .red: return isEnabled ? (isPressed ? .themeRed50 : .themeLucian) : .themeGray50
            }
        }

        func backgroundColor(isEnabled _: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default, .red: return isPressed ? .themeSteel10 : .themeSteel20
            case .transparent: return .clear
            }
        }
    }
}
