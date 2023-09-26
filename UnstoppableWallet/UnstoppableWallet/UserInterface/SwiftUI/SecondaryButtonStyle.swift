import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    let style: Style

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
            .font(.themeSubhead1)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .clipShape(Capsule(style: .continuous))
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case `default`
        case transparent

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default, .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeGray50
            }
        }

        func backgroundColor(isEnabled _: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isPressed ? .themeSteel10 : .themeSteel20
            case .transparent: return .clear
            }
        }
    }
}
