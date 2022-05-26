enum LaunchScreen: String, CaseIterable {
    case auto
    case balance
    case marketOverview
    case watchlist

    var title: String {
        switch self {
        case .auto: return "appearance.launch_screen.auto".localized
        case .balance: return "appearance.launch_screen.balance".localized
        case .marketOverview: return "appearance.launch_screen.market_overview".localized
        case .watchlist: return "appearance.launch_screen.watchlist".localized
        }
    }

    var iconName: String {
        switch self {
        case .auto: return "settings_20"
        case .balance: return "wallet_20"
        case .marketOverview: return "chart_type_20"
        case .watchlist: return "star_20"
        }
    }

}
