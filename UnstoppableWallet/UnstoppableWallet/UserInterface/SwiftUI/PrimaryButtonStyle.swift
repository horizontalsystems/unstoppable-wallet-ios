import ComponentKit
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
            .backgrounded(style: style, isEnabled: isEnabled, isPressed: configuration.isPressed)
            .clipShape(Capsule(style: .continuous))
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    enum Style {
        case yellow
        case yellowGradient
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
            case .yellow, .yellowGradient: return isEnabled ? .themeDark : .themeGray50
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
            default: return .clear
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func backgrounded(style: PrimaryButtonStyle.Style, isEnabled: Bool, isPressed: Bool) -> some View {
        switch style {
        case .yellowGradient:
            if isEnabled {
                background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: 0xFFD000), Color(hex: 0xFFA800)]),
                        startPoint: UnitPoint(x: -0.5181, y: 0.5),
                        endPoint: .trailing
                    )
                ).opacity(isPressed ? 0.5 : 1)
            } else {
                background(Color.themeSteel20)
            }
        default:
            background(style.backgroundColor(isEnabled: isEnabled, isPressed: isPressed))
        }
    }
}
