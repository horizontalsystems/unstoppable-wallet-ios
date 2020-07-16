import Foundation

class PriceAlert {
    let coin: Coin
    var state: AlertState
    var lastRate: Decimal?

    init(coin: Coin, state: AlertState, lastRate: Decimal? = nil) {
        self.coin = coin
        self.state = state
        self.lastRate = lastRate
    }

}

//extension TrendAlert.State {
//
//    var topicValue: String {
//        switch self {
//        case .off: return ""
//        case .short: return "7days"
//        case .long: return "6month"
//        }
//    }
//
//}
