import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    let style: Style
    let leftAccessory: Accessory
    let rightAccessory: Accessory

    init(style: Style = .default, leftAccessory: Accessory = .none, rightAccessory: Accessory = .none) {
        self.style = style
        self.leftAccessory = leftAccessory
        self.rightAccessory = rightAccessory
    }

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .margin4) {
            accessoryView(accessory: leftAccessory, configuration: configuration)
            labelView(configuration: configuration)
            accessoryView(accessory: rightAccessory, configuration: configuration)
        }
        .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
        .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
        .clipShape(Capsule(style: .continuous))
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    @ViewBuilder func labelView(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeSubhead1)
            .foregroundColor(style.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
    }

    @ViewBuilder func accessoryView(accessory: Accessory, configuration: Configuration) -> some View {
        if let icon = accessory.icon {
            Image(icon)
                .renderingMode(.template)
                .foregroundColor(accessory.foregroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
        } else {
            EmptyView()
        }
    }

    enum Style {
        case `default`
        case transparent

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default, .transparent: return isEnabled ? (isPressed ? .themeGray : .themeLeah) : .themeGray50
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isEnabled ? (isPressed ? .themeSteel10 : .themeSteel20) : .themeSteel20
            case .transparent: return .clear
            }
        }
    }

    enum Accessory {
        static let pressedColor = Color.themeGray
        static let enabledColor = Color.themeGray
        static let disabledColor = Color.themeGray50

        case none
        case dropDown
        case info
        case custom(icon: String, pressedColor: Color = Self.pressedColor, activeColor: Color = Self.enabledColor, disabledColor: Color = Self.disabledColor)

        var icon: String? {
            switch self {
            case .none: return nil
            case .dropDown: return "arrow_small_down_20"
            case .info: return "circle_information_20"
            case let .custom(icon, _, _, _): return icon
            }
        }

        func foregroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case let .custom(_, pressed, enabled, disabled): return isEnabled ? (isPressed ? pressed : enabled) : disabled
            default: return isEnabled ? (isPressed ? Self.pressedColor : Self.enabledColor) : Self.disabledColor
            }
        }
    }
}
