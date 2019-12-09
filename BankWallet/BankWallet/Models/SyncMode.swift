enum SyncMode: String {
    case fast
    case slow
    case new

    func title(coinTitle: String) -> String {
        switch self {
        case .fast: return "Horizontal Systems API"
        case .slow: return "\(coinTitle) Blockchain"
        case .new: return ""
        }
    }

}
