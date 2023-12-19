import SwiftUI
import ThemeKit

enum PriceChangeType {
    case up, down, unknown

    var color: Color {
        switch self {
        case .up: return .themeRemus
        case .down: return .themeLucian
        case .unknown: return .themeGray
        }
    }
}
