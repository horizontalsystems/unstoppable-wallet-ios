import Foundation

public enum CautionType: Equatable, Hashable {
    case error
    case warning

    public static func == (lhs: CautionType, rhs: CautionType) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error), (.warning, .warning): return true
        default: return false
        }
    }
}
