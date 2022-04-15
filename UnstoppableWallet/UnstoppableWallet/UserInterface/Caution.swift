import UIKit
import ThemeKit

struct Caution {
    let text: String
    let type: CautionType
}

enum CautionType: Equatable {
    case error
    case warning

    var labelColor: UIColor {
        switch self {
        case .error: return .themeLucian
        case .warning: return .themeJacob
        }
    }

    var borderColor: UIColor {
        switch self {
        case .error: return .themeRed50
        case .warning: return .themeYellow50
        }
    }

    static func ==(lhs: CautionType, rhs: CautionType) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error), (.warning, .warning): return true
        default: return false
        }
    }

}

struct TitledCaution: Equatable {
    let title: String
    let text: String
    let type: CautionType
}
