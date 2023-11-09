import SwiftUI

enum ThemeListStyle {
    case lawrence
    case bordered
    case transparent
}

struct ThemeListStyleModifier: ViewModifier {
    let themeListStyle: ThemeListStyle

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence:
            content
                .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
        case .bordered:
            content
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: .cornerRadius12).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
        case .transparent:
            content
        }
    }
}

struct ThemeListStyleButtonModifier: ViewModifier {
    let themeListStyle: ThemeListStyle
    let isPressed: Bool

    func body(content: Content) -> some View {
        switch themeListStyle {
        case .lawrence: content.background(isPressed ? Color.themeLawrencePressed : Color.themeLawrence)
        case .bordered, .transparent: content.background(isPressed ? Color.themeLawrencePressed : Color.themeTyler)
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
