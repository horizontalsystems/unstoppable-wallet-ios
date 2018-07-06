import Foundation

class CoinHelper {
    static let instance = CoinHelper()

    func formattedAmount(for value: CoinValue) -> String {
        return "\(value.value) \(value.coin.code)"
    }
}
