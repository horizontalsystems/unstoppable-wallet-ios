import SwiftUI

public enum ShortCutButtonType {
    case text(String)
    case icon(String)

    var isImage: Bool {
        switch self {
        case .icon: return true
        case .text: return false
        }
    }
}
