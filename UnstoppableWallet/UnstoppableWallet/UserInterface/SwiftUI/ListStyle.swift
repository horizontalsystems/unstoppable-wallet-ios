import SwiftUI

enum ListStyle {
    case lawrence
    case bordered

    var backgroundColor: Color {
        switch self {
        case .lawrence: return .themeLawrence
        case .bordered: return .clear
        }
    }

    var borderColor: Color {
        switch self {
        case .lawrence: return .clear
        case .bordered: return .themeSteel20
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
