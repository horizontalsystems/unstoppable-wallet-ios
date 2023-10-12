import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    let style: Style
    let isActive: Bool

    init(style: Style = .default, isActive: Bool = false) {
        self.style = style
        self.isActive = isActive
    }

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
            .font(.themeSubhead1)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isActive: isActive, isPressed: configuration.isPressed))
            .background(style.backgroundColor(isEnabled: isEnabled, isActive: isActive, isPressed: configuration.isPressed))
            .clipShape(Capsule(style: .continuous))
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case `default`
        case transparent

        func foregroundColor(isEnabled: Bool, isActive: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default, .transparent: return isEnabled ? (isActive ? .themeDark : (isPressed ? .themeGray : .themeLeah)) : .themeGray50
            }
        }

        func backgroundColor(isEnabled: Bool, isActive: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isEnabled ? (isActive ? (isPressed ? .themeYellow50 : .themeYellow) : (isPressed ? .themeSteel10 : .themeSteel20)) : .themeSteel20
            case .transparent: return isEnabled && isActive ? (isPressed ? .themeYellow50 : .themeYellow) : .clear
            }
        }
    }
}
