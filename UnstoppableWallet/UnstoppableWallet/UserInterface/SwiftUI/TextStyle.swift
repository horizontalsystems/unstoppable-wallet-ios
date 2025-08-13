import SwiftUI

enum TextStyle {
    case body
    case subhead
    case subheadSB
    case headline2
    case captionSB
    case title2
    case microSB

    var font: Font {
        switch self {
        case .body: return .manRopeFont(size: 16, weight: .medium)
        case .subhead: return .manRopeFont(size: 14, weight: .medium)
        case .subheadSB: return .manRopeFont(size: 14, weight: .semibold)
        case .headline2: return .manRopeFont(size: 16, weight: .semibold)
        case .captionSB: return .manRopeFont(size: 12, weight: .semibold)
        case .title2: return .manRopeFont(size: 36, weight: .medium)
        case .microSB: return .manRopeFont(size: 10, weight: .semibold)
        }
    }

    var defaultColorStyle: ColorStyle {
        switch self {
        case .body, .headline2, .title2, .subheadSB, .microSB: return .primary
        case .subhead, .captionSB: return .secondary
        }
    }
}
