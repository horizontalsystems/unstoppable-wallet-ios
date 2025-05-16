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
        case active
        case `default`
        case transparent

        init(style: PrimaryButton.Style) {
            switch style {
//            case .yellow: self = .yellow    //TODO: CHANGE THIS!
            case .active: self = .active
            case .default: self = .default
            case .transparent: self = .transparent
            }
        }

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .yellow, .yellowGradient: return isEnabled ? .themeDark : .themeGray50
            case .active: return isEnabled ? .themeLawrence : .themeAndy
            case .default: return isEnabled ? .themeTyler : .themeAndy
            case .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeAndy
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .yellow: return isEnabled ? (isPressed ? .themeYellow.pressed : .themeYellow) : .themeSteel20
            case .active: return isEnabled ? (isPressed ? .themeOrange.pressed : .themeOrange) : .themeBlade
            case .default: return isEnabled ? (isPressed ? .themeLeah.pressed : .themeLeah) : .themeBlade
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
