import Foundation

struct CoinValue {

    let coin: Coin
    let value: Double

}

extension CoinValue {

    var formattedAmount: String {
        return "\(value) \(coin.code)"
    }

}