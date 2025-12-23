enum ValueLevel {
    case regular
    case warning
    case error

    var colorStyle: ColorStyle {
        switch self {
        case .regular: return .primary
        case .warning: return .yellow
        case .error: return .red
        }
    }
}
