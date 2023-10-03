import SwiftUI
import ThemeKit

enum CautionState: Equatable {
    case none
    case caution(Caution)

    var caution: Caution? {
        switch self {
        case let .caution(caution): return caution
        default: return nil
        }
    }

    var color: Color {
        switch self {
        case .none: return Color.clear
        case let .caution(caution):
            switch caution.type {
            case .warning: return .themeJacob
            case .error: return .themeLucian
            }
        }
    }
}

struct Caution: Equatable {
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

    static func == (lhs: CautionType, rhs: CautionType) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error), (.warning, .warning): return true
        default: return false
        }
    }
}

class TitledCaution: Equatable {
    let title: String
    let text: String
    let type: CautionType

    init(title: String, text: String, type: CautionType) {
        self.title = title
        self.text = text
        self.type = type
    }

    static func == (lhs: TitledCaution, rhs: TitledCaution) -> Bool {
        lhs.title == rhs.title &&
                lhs.text == rhs.text &&
                lhs.type == rhs.type
    }
}

class CancellableTitledCaution: TitledCaution {
    let cancellable: Bool

    init(title: String, text: String, type: CautionType, cancellable: Bool) {
        self.cancellable = cancellable

        super.init(title: title, text: text, type: type)
    }
}
