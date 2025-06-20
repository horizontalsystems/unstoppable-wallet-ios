import SwiftUI

struct SecondaryActiveButtonStyle: ButtonStyle {
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
        HStack(spacing: .margin2) {
            accessoryView(accessory: leftAccessory, configuration: configuration)
            labelView(configuration: configuration)
            accessoryView(accessory: rightAccessory, configuration: configuration)
        }
        .padding(.leading, leftAccessory.padding)
        .padding(.trailing, rightAccessory.padding)
        .frame(height: 28)
        .background(style.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed))
        .clipShape(Capsule(style: .continuous))
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    @ViewBuilder func labelView(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeCaptionSB)
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

        func foregroundColor(isEnabled: Bool, isPressed _: Bool) -> Color {
            switch self {
            case .default, .transparent: return isEnabled ? .themeDark : .themeAndy
            }
        }

        func backgroundColor(isEnabled: Bool, isPressed: Bool) -> Color {
            switch self {
            case .default: return isEnabled ? (isPressed ? .themeYellow50 : .themeYellow) : .themeBlade
            case .transparent: return isEnabled ? (isPressed ? .themeYellow50 : .themeYellow) : .clear
            }
        }
    }

    enum Accessory {
        static let enabledColor = Color.themeDark
        static let disabledColor = Color.themeAndy

        case none
        case dropDown
        case info
        case custom(icon: String, enabledColor: Color = Self.enabledColor, disabledColor: Color = Self.disabledColor)

        var icon: String? {
            switch self {
            case .none: return nil
            case .dropDown: return "arrow_small_down_20"
            case .info: return "circle_information_20"
            case let .custom(icon, _, _): return icon
            }
        }

        var padding: CGFloat {
            switch self {
            case .none: return .margin16
            default: return .margin8
            }
        }

        func foregroundColor(isEnabled: Bool, isPressed _: Bool) -> Color {
            switch self {
            case let .custom(_, enabled, disabled): return isEnabled ? enabled : disabled
            default: return isEnabled ? Self.enabledColor : Self.disabledColor
            }
        }
    }
}
