import SwiftUI

enum ColorStyle {
    case primary
    case secondary
    case andy
    case red
    case green
    case yellow

    var color: Color {
        color()
    }

    func color(dimmed: Bool = false) -> Color {
        switch self {
        case .primary: return dimmed ? .themeAndy : .themeLeah
        case .secondary: return dimmed ? .themeAndy : .themeGray
        case .andy: return .themeAndy.opacity(dimmed ? 0.5 : 1)
        case .red: return .themeLucian.opacity(dimmed ? 0.5 : 1)
        case .green: return .themeRemus.opacity(dimmed ? 0.5 : 1)
        case .yellow: return .themeJacob.opacity(dimmed ? 0.5 : 1)
        }
    }
}
