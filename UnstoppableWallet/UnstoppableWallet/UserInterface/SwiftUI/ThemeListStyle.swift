import SwiftUI

enum ThemeListStyle {
    case lawrence
    case bordered
    case borderedLawrence
    case transparent
    case transparentInline
    case blur
    case steel10WithCorners(UIRectCorner)
}

struct ThemeListStyleModifier: ViewModifier {
    private let themeListStyle: ThemeListStyle
    private let cornerRadius: CGFloat
    private let selected: Bool

    init(themeListStyle: ThemeListStyle = .lawrence, cornerRadius: CGFloat = 12, selected: Bool = false) { // TODO: put params
        self.themeListStyle = themeListStyle
        self.cornerRadius = cornerRadius
        self.selected = selected
    }

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence:
            content
                .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Color.themeLawrence))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .borderedLawrence:
            content
                .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Color.themeLawrence))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(selected ? Color.themeJacob : Color.themeBlade, lineWidth: .heightOneDp))
        case .bordered:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(selected ? Color.themeJacob : Color.themeBlade, lineWidth: .heightOneDp))
        case .transparent, .transparentInline:
            content
        case .blur:
            content
                .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case let .steel10WithCorners(corners):
            content
                .background(RoundedCorner(radius: cornerRadius, corners: corners).fill(Color.themeBlade))
                .clipShape(RoundedCorner(radius: cornerRadius, corners: corners))
        }
    }
}

struct ThemeListStyleButtonModifier: ViewModifier {
    let themeListStyle: ThemeListStyle
    let isPressed: Bool

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence, .borderedLawrence: content.background(isPressed ? Color.themeLawrence.pressed : Color.themeLawrence)
        case .bordered: content.background(isPressed ? Color.themeLawrence.pressed : Color.clear)
        case .transparent, .transparentInline: content.background(isPressed ? Color.themeLawrence.pressed : Color.themeTyler)
        case .blur, .steel10WithCorners: content
        }
    }
}

struct ThemeListStyleKey: EnvironmentKey {
    static let defaultValue = ThemeListStyle.lawrence
}

extension EnvironmentValues {
    var themeListStyle: ThemeListStyle {
        get { self[ThemeListStyleKey.self] }
        set { self[ThemeListStyleKey.self] = newValue }
    }
}

extension View {
    func themeListStyle(_ themeListStyle: ThemeListStyle) -> some View {
        environment(\.themeListStyle, themeListStyle)
    }
}
