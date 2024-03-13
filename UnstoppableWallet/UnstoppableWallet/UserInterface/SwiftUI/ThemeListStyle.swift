import SwiftUI

enum ThemeListStyle {
    case lawrence
    case bordered
    case borderedLawrence
    case transparent
    case transparentInline
}

struct ThemeListStyleModifier: ViewModifier {
    private let themeListStyle: ThemeListStyle
    private let cornerRadius: CGFloat
    private let selected: Bool

    init(themeListStyle: ThemeListStyle = .lawrence, cornerRadius: CGFloat = .cornerRadius12, selected: Bool = false) {
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
                .background(Color.themeLawrence)
        case .bordered:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(selected ? Color.themeJacob : Color.themeSteel20, lineWidth: .heightOneDp))
        case .transparent, .transparentInline:
            content
        }
    }
}

struct ThemeListStyleButtonModifier: ViewModifier {
    let themeListStyle: ThemeListStyle
    let isPressed: Bool

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence, .borderedLawrence: content.background(isPressed ? Color.themeLawrencePressed : Color.themeLawrence)
        case .bordered, .transparent, .transparentInline: content.background(isPressed ? Color.themeLawrencePressed : Color.themeTyler)
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
