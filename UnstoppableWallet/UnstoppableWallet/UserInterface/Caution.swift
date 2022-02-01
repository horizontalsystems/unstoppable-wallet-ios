import UIKit
import ThemeKit

struct Caution {
    let text: String
    let type: CautionType
}

enum CautionType {
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

}

struct TitledCaution {
    let title: String
    let text: String
    let type: CautionType
}
