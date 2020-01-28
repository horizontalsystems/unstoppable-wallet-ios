enum SyncMode: String {
    case fast
    case slow
    case new

    var title: String {
        switch self {
        case .fast: return "API"
        case .slow: return "sync_mode.from_blockchain".localized
        case .new: return ""
        }
    }

}
