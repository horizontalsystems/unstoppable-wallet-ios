enum LaunchScreen: String, CaseIterable {
    case auto
    case balance
    case marketOverview
    case watchlist

    var title: String {
        switch self {
        case .auto: return "launch_screen.auto".localized
        case .balance: return "launch_screen.balance".localized
        case .marketOverview: return "launch_screen.market_overview".localized
        case .watchlist: return "launch_screen.watchlist".localized
        }
    }

}
