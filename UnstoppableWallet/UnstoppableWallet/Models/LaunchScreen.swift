enum LaunchScreen: String, CaseIterable {
    case auto
    case balance
    case watchlist

    var title: String {
        switch self {
        case .auto: return "appearance.launch_screen.auto".localized
        case .balance: return "appearance.launch_screen.balance".localized
        case .watchlist: return "appearance.launch_screen.watchlist".localized
        }
    }

    var iconName: String {
        switch self {
        case .auto: return "settings_24"
        case .balance: return "wallet_24"
        case .watchlist: return "heart_24"
        }
    }
}

extension LaunchScreen: Codable {
    enum CodingKeys: String, CodingKey {
        case auto
        case balance
        case watchlist
    }

    var statType: String {
        switch self {
        case .auto: return "auto"
        case .balance: return "balance"
        case .watchlist: return "watchlist"
        }
    }
}
