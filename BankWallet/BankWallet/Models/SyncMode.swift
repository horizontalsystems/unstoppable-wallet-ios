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

    var description: String {
        switch self {
        case .fast: return "settings_privacy.alert_sync.recommended".localized
        case .slow: return "settings_privacy.alert_sync.more_private".localized
        case .new: return ""
        }
    }

}
