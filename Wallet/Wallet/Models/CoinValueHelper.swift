import Foundation

class CoinValueHelper {

    static func formattedAmount(for value: CoinValue) -> String {
        return "\(value.value) \(value.coin.code)"
    }

}
