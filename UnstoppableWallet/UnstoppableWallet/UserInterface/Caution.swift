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

enum TitledCautionState: Equatable {
    case none
    case caution(TitledCaution)

    var caution: TitledCaution? {
        switch self {
        case let .caution(caution): return caution
        default: return nil
        }
    }
}

enum FieldCautionState: Equatable {
    case none
    case caution(CautionType)

    var color: Color {
        switch self {
        case .none: return Color.clear
        case let .caution(type):
            switch type {
            case .warning: return .themeJacob
            case .error: return .themeLucian
            }
        }
    }
}

struct Caution: Equatable {
    let text: String
    let type: CautionType

    func cautionNew(title: String? = nil) -> CautionNew {
        .init(title: title, text: text, type: type)
    }
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
        case .error: return .themeLucian
        case .warning: return .themeYellowD
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

struct CautionNew: Equatable {
    let title: String?
    let text: String
    let type: CautionType

    init(title: String? = nil, text: String, type: CautionType) {
        self.title = title
        self.text = text
        self.type = type
    }
}
