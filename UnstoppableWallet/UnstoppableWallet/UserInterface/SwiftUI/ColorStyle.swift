import SwiftUI

enum ColorStyle {
    case primary
    case secondary
    case lawrence
    case andy
    case dark
    case red
    case green
    case yellow

    init(diff: Decimal) {
        self = diff == 0 ? .secondary : (diff.isSignMinus ? .red : .green)
    }

    var color: Color {
        color()
    }

    func color(dimmed: Bool = false) -> Color {
        switch self {
        case .primary: return dimmed ? .themeAndy : .themeLeah
        case .secondary: return dimmed ? .themeAndy : .themeGray
        case .lawrence: return .themeLawrence.opacity(dimmed ? 0.5 : 1)
        case .andy: return .themeAndy.opacity(dimmed ? 0.5 : 1)
        case .dark: return .themeDark.opacity(dimmed ? 0.5 : 1)
        case .red: return .themeLucian.opacity(dimmed ? 0.5 : 1)
        case .green: return .themeRemus.opacity(dimmed ? 0.5 : 1)
        case .yellow: return .themeJacob.opacity(dimmed ? 0.5 : 1)
        }
    }
}
