import SwiftUI

struct SecondaryCircleButtonStyle: ButtonStyle {
    private let style: Style
    private let isActive: Bool

    @Environment(\.isEnabled) private var isEnabled

    init(style: Style = .default, isActive: Bool = false) {
        self.style = style
        self.isActive = isActive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.margin4)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isActive: isActive, isPressed: configuration.isPressed))
            .background(style.backgroundColor(isEnabled: isEnabled, isActive: isActive, isPressed: configuration.isPressed))
            .clipShape(Circle())
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case `default`
        case transparent
        case red

        func foregroundColor(isEnabled: Bool, isActive: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isEnabled ? (isActive ? .themeDark : (isPressed ? .themeGray : .themeLeah)) : .themeAndy
            case .transparent: return isEnabled ? (isPressed ? .themeGray50 : .themeGray) : .themeAndy
            case .red: return isEnabled ? (isPressed ? .themeRed50 : .themeLucian) : .themeAndy
            }
        }

        func backgroundColor(isEnabled _: Bool, isActive: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isActive ? (isPressed ? .themeYellow50 : .themeYellow) : (isPressed ? .themeBlade : .themeBlade)
            case .red: return isPressed ? .themeBlade : .themeBlade
            case .transparent: return .clear
            }
        }
    }
}
