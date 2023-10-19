import SwiftUI

enum ListStyle {
    case lawrence
    case bordered
    case transparent
}

struct ListStyleModifier: ViewModifier {
    let listStyle: ListStyle

    func body(content: Content) -> some View {
        switch listStyle {
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

struct ListStyleButtonModifier: ViewModifier {
    let listStyle: ListStyle
    let isPressed: Bool

    func body(content: Content) -> some View {
        switch listStyle {
        case .lawrence: content.background(isPressed ? Color.themeLawrencePressed : Color.themeLawrence)
        case .bordered, .transparent: content.background(isPressed ? Color.themeLawrencePressed : Color.clear)
        }
    }
}

struct ListStyleKey: EnvironmentKey {
    static let defaultValue = ListStyle.lawrence
}

extension EnvironmentValues {
    var listStyle: ListStyle {
        get { self[ListStyleKey.self] }
        set { self[ListStyleKey.self] = newValue }
    }
}

extension View {
    func listStyle(_ listStyle: ListStyle) -> some View {
        environment(\.listStyle, listStyle)
    }
}
