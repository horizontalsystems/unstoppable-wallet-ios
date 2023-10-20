import SwiftUI

enum CoinPriceListMode {
    case topCoins
    case watchlist

    var title: LocalizedStringKey {
        switch self {
        case .topCoins: return "top_coins.title"
        case .watchlist: return "watchlist.title"
        }
    }

    var isWatchlist: Bool {
        switch self {
        case .watchlist: return true
        default: return false
        }
    }
}
