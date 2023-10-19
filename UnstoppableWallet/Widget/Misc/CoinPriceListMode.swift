enum CoinPriceListMode {
    case topCoins
    case watchlist

    var title: String {
        switch self {
        case .topCoins: return "Top Coins"
        case .watchlist: return "Watchlist"
        }
    }

    var isWatchlist: Bool {
        switch self {
        case .watchlist: return true
        default: return false
        }
    }
}
