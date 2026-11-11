import SwiftUI

public enum TextStyle {
    case body
    case bodyR
    case subhead
    case subheadSB
    case subheadR
    case subheadI
    case headline1
    case headline2
    case headlineB
    case caption
    case captionSB
    case title2
    case title3
    case microSB

    var font: Font {
        switch self {
        case .body: return .manRopeFont(size: 16, weight: .medium)
        case .bodyR: return .manRopeFont(size: 16, weight: .regular)
        case .subhead: return .manRopeFont(size: 14, weight: .medium)
        case .subheadSB: return .manRopeFont(size: 14, weight: .semibold)
        case .subheadR: return .manRopeFont(size: 14, weight: .regular)
        case .subheadI: return .manRopeFont(size: 14, weight: .medium).italic()
        case .headline1: return .manRopeFont(size: 20, weight: .semibold)
        case .headline2: return .manRopeFont(size: 16, weight: .semibold)
        case .headlineB: return .manRopeFont(size: 16, weight: .bold)
        case .caption: return .manRopeFont(size: 12, weight: .regular)
        case .captionSB: return .manRopeFont(size: 12, weight: .semibold)
        case .title2: return .manRopeFont(size: 36, weight: .medium)
        case .title3: return .manRopeFont(size: 24, weight: .semibold)
        case .microSB: return .manRopeFont(size: 10, weight: .semibold)
        }
    }

    var defaultColorStyle: ColorStyle {
        switch self {
        case .body, .bodyR, .headline1, .headline2, .headlineB, .title2, .title3, .subheadSB, .microSB: return .primary
        case .subhead, .subheadR, .subheadI, .caption, .captionSB: return .secondary
        }
    }
}
