import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let style: Style

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 15, leading: .margin32, bottom: 15, trailing: .margin32))
            .font(.themeHeadline2)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
            .clipShape(Capsule(style: .continuous))
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case yellow
        case red
        case gray
        case transparent

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
