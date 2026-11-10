public enum ValueLevel {
    case regular
    case warning
    case error

    var colorStyle: ColorStyle {
        switch self {
        case .regular: return .primary
        case .warning: return .warning
        case .error: return .red
        }
    }
}
