import SwiftUI

enum ThemeListStyle {
    case lawrence
    case bordered
    case borderedLawrence
    case transparent
    case transparentInline

}

struct ThemeListStyleModifier: ViewModifier {
    let themeListStyle: ThemeListStyle

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence:
            content
                .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
        case .borderedLawrence:
            content
                .background(Color.themeLawrence)
        case .bordered:
            content
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: .cornerRadius12).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
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
