import SwiftUI

enum TextStyle {
    case title1
    case title2M
    case title2R
    case title3
    case title3B
    case headline1
    case headline2
    case body
    case bodyR
    case subhead
    case subheadR
    case subheadSB
    case caption
    case captionSB
    case micro
    case microSB

    var font: Font {
        switch self {
        case .title1: return .manRopeFont(size: 38, weight: .semibold)
        case .title2M: return .manRopeFont(size: 36, weight: .medium)
        case .title2R: return .manRopeFont(size: 32, weight: .regular)
        case .title3: return .manRopeFont(size: 24, weight: .semibold)
        case .title3B: return .manRopeFont(size: 24, weight: .bold)
        case .headline1: return .manRopeFont(size: 20, weight: .semibold)
        case .headline2: return .manRopeFont(size: 16, weight: .semibold)
        case .body: return .manRopeFont(size: 16, weight: .medium)
        case .bodyR: return .manRopeFont(size: 16, weight: .regular)
        case .subhead: return .manRopeFont(size: 14, weight: .medium)
        case .subheadR: return .manRopeFont(size: 14, weight: .regular)
        case .subheadSB: return .manRopeFont(size: 14, weight: .semibold)
        case .caption: return .manRopeFont(size: 12, weight: .regular)
        case .captionSB: return .manRopeFont(size: 12, weight: .semibold)
        case .micro: return .manRopeFont(size: 10, weight: .regular)
        case .microSB: return .manRopeFont(size: 10, weight: .semibold)
        }
    }
}
